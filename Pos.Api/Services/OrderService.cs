using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface IOrderService
{
    Task<List<OrderResponse>> ListAsync();
    Task<OrderResponse> GetAsync(Guid id);
    Task<OrderResponse> CreateAsync(OrderCreateRequest request);
    Task<OrderResponse> UpdateStatusAsync(Guid id, string status);
}

public class OrderService : IOrderService
{
    private readonly PosDbContext _db;
    private readonly ITenantContext _tenant;

    public OrderService(PosDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<List<OrderResponse>> ListAsync()
    {
        var orders = await _db.Orders
            .Include(o => o.OrderLines)
            .Include(o => o.Payments)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();
        return orders.Select(ToResponse).ToList();
    }

    public async Task<OrderResponse> GetAsync(Guid id)
    {
        var o = await _db.Orders
            .Include(o => o.OrderLines)
            .Include(o => o.Payments)
            .FirstOrDefaultAsync(o => o.Id == id)
            ?? throw new NotFoundException("Order not found.");
        return ToResponse(o);
    }

    public async Task<OrderResponse> CreateAsync(OrderCreateRequest request)
    {
        if (request.Lines is null || request.Lines.Count == 0)
            throw new AppException("Order must have at least one order line.");

        var restaurantId = _tenant.RequireRestaurantId();
        var userId = _tenant.RequireUserId();

        // Cross-tenant guards.
        var storeExists = await _db.Stores.AnyAsync(s => s.Id == request.StoreId);
        if (!storeExists)
            throw new AppException("StoreId does not belong to your restaurant.");

        var productIds = request.Lines.Select(l => l.ProductId).Distinct().ToList();
        var products = await _db.Products
            .Where(p => productIds.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id);

        if (products.Count != productIds.Count)
            throw new AppException("One or more ProductIds do not belong to your restaurant.");

        var now = DateTime.UtcNow;
        var order = new Order
        {
            Id = Guid.NewGuid(),
            RestaurantId = restaurantId,
            StoreId = request.StoreId,
            OrderNumber = await GenerateOrderNumberAsync(restaurantId, now),
            Status = "Pending",
            DiscountAmount = request.DiscountAmount,
            TaxAmount = request.TaxAmount,
            CreatedByUserId = userId,
            CreatedAt = now,
            PaymentStatus = "Unpaid"
        };

        decimal subtotal = 0m;
        foreach (var l in request.Lines)
        {
            if (l.Quantity <= 0)
                throw new AppException("Quantity must be > 0.");

            var product = products[l.ProductId];
            var lineTotal = (l.Quantity * l.UnitPrice) - l.DiscountAmount;
            if (lineTotal < 0) lineTotal = 0;

            order.OrderLines.Add(new OrderLine
            {
                Id = Guid.NewGuid(),
                RestaurantId = restaurantId,
                OrderId = order.Id,
                ProductId = product.Id,
                ProductName = product.Name,
                Quantity = l.Quantity,
                UnitPrice = l.UnitPrice,
                DiscountAmount = l.DiscountAmount,
                LineTotal = lineTotal
            });
            subtotal += lineTotal;
        }

        order.Subtotal = subtotal;
        order.TotalAmount = subtotal + order.TaxAmount - order.DiscountAmount;
        if (order.TotalAmount < 0) order.TotalAmount = 0;

        if (!string.IsNullOrWhiteSpace(request.PaymentMethod) && request.PaymentAmount is > 0)
        {
            order.Payments.Add(new Payment
            {
                Id = Guid.NewGuid(),
                RestaurantId = restaurantId,
                OrderId = order.Id,
                PaymentMethod = request.PaymentMethod!,
                Amount = request.PaymentAmount.Value,
                Reference = request.PaymentReference,
                PaidAt = now
            });
            order.PaymentStatus = request.PaymentAmount.Value >= order.TotalAmount ? "Paid" : "Partial";
            order.Status = order.PaymentStatus == "Paid" ? "Completed" : "Pending";
        }

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();
        return ToResponse(order);
    }

    public async Task<OrderResponse> UpdateStatusAsync(Guid id, string status)
    {
        if (string.IsNullOrWhiteSpace(status))
            throw new AppException("Status is required.");
        var o = await _db.Orders
            .Include(o => o.OrderLines)
            .Include(o => o.Payments)
            .FirstOrDefaultAsync(o => o.Id == id)
            ?? throw new NotFoundException("Order not found.");
        o.Status = status.Trim();
        await _db.SaveChangesAsync();
        return ToResponse(o);
    }

    private async Task<string> GenerateOrderNumberAsync(Guid restaurantId, DateTime now)
    {
        // Per-tenant counter scoped to the day: ORD-YYYYMMDD-#### within the tenant.
        var datePart = now.ToString("yyyyMMdd");
        var prefix = $"ORD-{datePart}-";

        var countToday = await _db.Orders
            .CountAsync(o => o.RestaurantId == restaurantId && o.OrderNumber.StartsWith(prefix));

        return $"{prefix}{(countToday + 1).ToString("D4")}";
    }

    private static OrderResponse ToResponse(Order o) =>
        new(o.Id, o.StoreId, o.OrderNumber, o.Status, o.Subtotal, o.TaxAmount,
            o.DiscountAmount, o.TotalAmount, o.PaymentStatus, o.CreatedByUserId, o.CreatedAt,
            o.OrderLines.Select(l => new OrderLineResponse(
                l.Id, l.ProductId, l.ProductName, l.Quantity, l.UnitPrice, l.DiscountAmount, l.LineTotal)).ToList(),
            o.Payments.Select(p => new PaymentResponse(
                p.Id, p.PaymentMethod, p.Amount, p.Reference, p.PaidAt)).ToList());
}
