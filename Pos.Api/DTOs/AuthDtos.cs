using System.ComponentModel.DataAnnotations;

namespace Pos.Api.DTOs;

public record LoginRequest(
    [Required, EmailAddress] string Email,
    [Required] string Password);

public record LoginResponse(
    string Token,
    Guid UserId,
    string FullName,
    string Email,
    string Role,
    Guid RestaurantId,
    string RestaurantName,
    string RestaurantSlug);
