using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record TenantSignupRequest(
    [Required] TenantSignupRestaurant Restaurant,
    [Required] TenantSignupAdmin Admin);

public record TenantSignupRestaurant(
    [Required, MaxLength(200)] string Name,
    [Required, MaxLength(40)] string Slug,
    [Required, EmailAddress, MaxLength(256)] string ContactEmail,
    [MaxLength(50)] string? Phone);

public record TenantSignupAdmin(
    [Required, MaxLength(200)] string FullName,
    [Required, EmailAddress, MaxLength(256)] string Email,
    [Required, MinLength(8)] string Password);

public record TenantResponse(
    Guid Id,
    string Name,
    string Slug,
    string ContactEmail,
    string? Phone,
    bool IsActive,
    DateTime CreatedAt);

public record TenantUpdateRequest(
    [Required, MaxLength(200)] string Name,
    [Required, EmailAddress, MaxLength(256)] string ContactEmail,
    [MaxLength(50)] string? Phone);
