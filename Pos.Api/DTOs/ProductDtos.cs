using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record ProductResponse(
    Guid Id,
    Guid CategoryId,
    string CategoryName,
    string Name,
    string? NameLocalized,
    string? AltLanguageCode,
    string? Description,
    string? Sku,
    string? Barcode,
    decimal Price,
    decimal? CostPrice,
    string? ImageUrl,
    bool IsActive,
    DateTime CreatedAt);

public record ProductCreateRequest(
    [Required] Guid CategoryId,
    [Required, MaxLength(200)] string Name,
    [MaxLength(200)] string? NameLocalized,
    [MaxLength(8)] string? AltLanguageCode,
    [MaxLength(2000)] string? Description,
    [MaxLength(100)] string? Sku,
    [MaxLength(100)] string? Barcode,
    [Range(0, double.MaxValue, ErrorMessage = "Price must be >= 0.")] decimal Price,
    [Range(0, double.MaxValue)] decimal? CostPrice,
    [MaxLength(1000)] string? ImageUrl,
    bool IsActive = true);

public record ProductUpdateRequest(
    [Required] Guid CategoryId,
    [Required, MaxLength(200)] string Name,
    [MaxLength(200)] string? NameLocalized,
    [MaxLength(8)] string? AltLanguageCode,
    [MaxLength(2000)] string? Description,
    [MaxLength(100)] string? Sku,
    [MaxLength(100)] string? Barcode,
    [Range(0, double.MaxValue, ErrorMessage = "Price must be >= 0.")] decimal Price,
    [Range(0, double.MaxValue)] decimal? CostPrice,
    [MaxLength(1000)] string? ImageUrl,
    bool IsActive);
