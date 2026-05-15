using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record PaymentCreateRequest(
    [Required] string PaymentMethod,
    [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be > 0.")] decimal Amount,
    [MaxLength(200)] string? Reference);
