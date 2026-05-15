using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface IStoreService
{
    Task<List<StoreResponse>> ListAsync();
    Task<StoreResponse> GetAsync(Guid id);
    Task<StoreResponse> CreateAsync(StoreCreateRequest request);
    Task<StoreResponse> UpdateAsync(Guid id, StoreUpdateRequest request);
}

public class StoreService : IStoreService
{
    private readonly PosDbContext _db;
    private readonly ITenantContext _tenant;

    public StoreService(PosDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<List<StoreResponse>> ListAsync() =>
        await _db.Stores
            .OrderBy(s => s.Name)
            .Select(s => new StoreResponse(s.Id, s.Name, s.Address, s.Phone, s.IsActive, s.CreatedAt))
            .ToListAsync();

    public async Task<StoreResponse> GetAsync(Guid id)
    {
        var s = await _db.Stores.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Store not found.");
        return ToResponse(s);
    }

    public async Task<StoreResponse> CreateAsync(StoreCreateRequest request)
    {
        var s = new Store
        {
            Id = Guid.NewGuid(),
            RestaurantId = _tenant.RequireRestaurantId(),
            Name = request.Name.Trim(),
            Address = request.Address,
            Phone = request.Phone,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };
        _db.Stores.Add(s);
        await _db.SaveChangesAsync();
        return ToResponse(s);
    }

    public async Task<StoreResponse> UpdateAsync(Guid id, StoreUpdateRequest request)
    {
        var s = await _db.Stores.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Store not found.");
        s.Name = request.Name.Trim();
        s.Address = request.Address;
        s.Phone = request.Phone;
        s.IsActive = request.IsActive;
        await _db.SaveChangesAsync();
        return ToResponse(s);
    }

    private static StoreResponse ToResponse(Store s) =>
        new(s.Id, s.Name, s.Address, s.Phone, s.IsActive, s.CreatedAt);
}
