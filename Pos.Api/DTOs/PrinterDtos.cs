using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record PrinterResponse(
    Guid Id,
    Guid StoreId,
    string Name,
    string IpAddress,
    int Port,
    string PrinterType,
    bool IsActive,
    DateTime CreatedAt);

public record PrinterCreateRequest(
    [Required] Guid StoreId,
    [Required, MaxLength(200)] string Name,
    [Required, MaxLength(45)] string IpAddress,
    [Range(1, 65535)] int Port,
    [Required, MaxLength(50)] string PrinterType,
    bool IsActive = true);

public record PrinterUpdateRequest(
    [Required] Guid StoreId,
    [Required, MaxLength(200)] string Name,
    [Required, MaxLength(45)] string IpAddress,
    [Range(1, 65535)] int Port,
    [Required, MaxLength(50)] string PrinterType,
    bool IsActive);
