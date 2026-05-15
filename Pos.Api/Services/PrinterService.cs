using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface IPrinterService
{
    Task<List<PrinterResponse>> ListByStoreAsync(Guid storeId);
    Task<PrinterResponse> GetAsync(Guid id);
    Task<PrinterResponse> CreateAsync(PrinterCreateRequest request);
    Task<PrinterResponse> UpdateAsync(Guid id, PrinterUpdateRequest request);
    Task DeleteAsync(Guid id);
}

public class PrinterService : IPrinterService
{
    private readonly PosDbContext _db;
    private readonly ITenantContext _tenant;

    public PrinterService(PosDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<List<PrinterResponse>> ListByStoreAsync(Guid storeId)
    {
        var storeExists = await _db.Stores.AnyAsync(s => s.Id == storeId);
        if (!storeExists)
            throw new NotFoundException("Store not found.");

        return await _db.Printers
            .Where(p => p.StoreId == storeId)
            .OrderBy(p => p.Name)
            .Select(p => ToResponse(p))
            .ToListAsync();
    }

    public async Task<PrinterResponse> GetAsync(Guid id)
    {
        var p = await _db.Printers.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Printer not found.");
        return ToResponse(p);
    }

    public async Task<PrinterResponse> CreateAsync(PrinterCreateRequest request)
    {
        var storeExists = await _db.Stores.AnyAsync(s => s.Id == request.StoreId);
        if (!storeExists)
            throw new AppException("StoreId does not belong to your restaurant.");

        var p = new Printer
        {
            Id = Guid.NewGuid(),
            RestaurantId = _tenant.RequireRestaurantId(),
            StoreId = request.StoreId,
            Name = request.Name.Trim(),
            IpAddress = request.IpAddress.Trim(),
            Port = request.Port,
            PrinterType = request.PrinterType.Trim(),
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };
        _db.Printers.Add(p);
        await _db.SaveChangesAsync();
        return ToResponse(p);
    }

    public async Task<PrinterResponse> UpdateAsync(Guid id, PrinterUpdateRequest request)
    {
        var p = await _db.Printers.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Printer not found.");

        if (p.StoreId != request.StoreId)
        {
            var storeExists = await _db.Stores.AnyAsync(s => s.Id == request.StoreId);
            if (!storeExists)
                throw new AppException("StoreId does not belong to your restaurant.");
            p.StoreId = request.StoreId;
        }

        p.Name = request.Name.Trim();
        p.IpAddress = request.IpAddress.Trim();
        p.Port = request.Port;
        p.PrinterType = request.PrinterType.Trim();
        p.IsActive = request.IsActive;
        await _db.SaveChangesAsync();
        return ToResponse(p);
    }

    public async Task DeleteAsync(Guid id)
    {
        var p = await _db.Printers.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Printer not found.");
        _db.Printers.Remove(p);
        await _db.SaveChangesAsync();
    }

    private static PrinterResponse ToResponse(Printer p) =>
        new(p.Id, p.StoreId, p.Name, p.IpAddress, p.Port, p.PrinterType, p.IsActive, p.CreatedAt);
}
