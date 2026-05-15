using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record OrderLineRequest(
    [Required] Guid ProductId,
    [Range(0.0001, double.MaxValue, ErrorMessage = "Quantity must be > 0.")] decimal Quantity,
    [Range(0, double.MaxValue)] decimal UnitPrice,
    [Range(0, double.MaxValue)] decimal DiscountAmount);

public record OrderCreateRequest(
    [Required] Guid StoreId,
    [Range(0, double.MaxValue)] decimal DiscountAmount,
    [Range(0, double.MaxValue)] decimal TaxAmount,
    string? PaymentMethod,
    string? PaymentReference,
    [Range(0, double.MaxValue)] decimal? PaymentAmount,
    [Required, MinLength(1, ErrorMessage = "Order must have at least one order line.")]
    List<OrderLineRequest> Lines);

public record OrderStatusUpdateRequest(
    [Required] string Status);

public record OrderLineResponse(
    Guid Id,
    Guid ProductId,
    string ProductName,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountAmount,
    decimal LineTotal);

public record PaymentResponse(
    Guid Id,
    string PaymentMethod,
    decimal Amount,
    string? Reference,
    DateTime PaidAt);

public record OrderResponse(
    Guid Id,
    Guid StoreId,
    string OrderNumber,
    string Status,
    decimal Subtotal,
    decimal TaxAmount,
    decimal DiscountAmount,
    decimal TotalAmount,
    string PaymentStatus,
    Guid CreatedByUserId,
    DateTime CreatedAt,
    List<OrderLineResponse> Lines,
    List<PaymentResponse> Payments);
