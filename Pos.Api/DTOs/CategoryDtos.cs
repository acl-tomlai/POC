using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record CategoryResponse(
    Guid Id,
    string Name,
    string? NameLocalized,
    string? AltLanguageCode,
    int DisplayOrder,
    bool IsActive,
    DateTime CreatedAt);

public record CategoryCreateRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(200)] string? NameLocalized,
    [MaxLength(8)] string? AltLanguageCode,
    int DisplayOrder,
    bool IsActive = true);

public record CategoryUpdateRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(200)] string? NameLocalized,
    [MaxLength(8)] string? AltLanguageCode,
    int DisplayOrder,
    bool IsActive);
