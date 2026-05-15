using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record UserResponse(
    Guid Id,
    string FullName,
    string Email,
    string Role,
    bool IsActive,
    DateTime CreatedAt);

public record UserCreateRequest(
    [Required, MaxLength(200)] string FullName,
    [Required, EmailAddress, MaxLength(256)] string Email,
    [Required, MinLength(8)] string Password,
    [Required] string Role);

public record UserUpdateRequest(
    [Required, MaxLength(200)] string FullName,
    [Required] string Role,
    bool IsActive);
