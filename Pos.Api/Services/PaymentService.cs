using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface IPaymentService
{
    Task<List<PaymentResponse>> ListByOrderAsync(Guid orderId);
    Task<PaymentResponse> CreateAsync(Guid orderId, PaymentCreateRequest request);
}

public class PaymentService : IPaymentService
{
    private readonly PosDbContext _db;
    private readonly ITenantContext _tenant;

    public PaymentService(PosDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<List<PaymentResponse>> ListByOrderAsync(Guid orderId)
    {
        var orderExists = await _db.Orders.AnyAsync(o => o.Id == orderId);
        if (!orderExists)
            throw new NotFoundException("Order not found.");

        return await _db.Payments
            .Where(p => p.OrderId == orderId)
            .OrderBy(p => p.PaidAt)
            .Select(p => new PaymentResponse(p.Id, p.PaymentMethod, p.Amount, p.Reference, p.PaidAt))
            .ToListAsync();
    }

    public async Task<PaymentResponse> CreateAsync(Guid orderId, PaymentCreateRequest request)
    {
        // Cross-tenant guard: order must belong to caller's tenant (filter handles it).
        var order = await _db.Orders
            .Include(o => o.Payments)
            .FirstOrDefaultAsync(o => o.Id == orderId)
            ?? throw new NotFoundException("Order not found.");

        var payment = new Payment
        {
            Id = Guid.NewGuid(),
            RestaurantId = _tenant.RequireRestaurantId(),
            OrderId = order.Id,
            PaymentMethod = request.PaymentMethod.Trim(),
            Amount = request.Amount,
            Reference = request.Reference,
            PaidAt = DateTime.UtcNow
        };
        _db.Payments.Add(payment);

        var paid = order.Payments.Sum(p => p.Amount) + payment.Amount;
        order.PaymentStatus = paid >= order.TotalAmount ? "Paid" : "Partial";
        if (order.PaymentStatus == "Paid" && order.Status == "Pending")
            order.Status = "Completed";

        await _db.SaveChangesAsync();
        return new PaymentResponse(payment.Id, payment.PaymentMethod, payment.Amount, payment.Reference, payment.PaidAt);
    }
}
