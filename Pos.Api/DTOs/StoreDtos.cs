using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record StoreResponse(
    Guid Id,
    string Name,
    string? Address,
    string? Phone,
    bool IsActive,
    DateTime CreatedAt);

public record StoreCreateRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(500)] string? Address,
    [MaxLength(50)] string? Phone,
    bool IsActive = true);

public record StoreUpdateRequest(
    [Required, MaxLength(200)] string Name,
    [MaxLength(500)] string? Address,
    [MaxLength(50)] string? Phone,
    bool IsActive);
