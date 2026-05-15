using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Helpers;

namespace Pos.Api.Services;

public interface IAuthService
{
    Task<LoginResponse> LoginAsync(LoginRequest request);
}

public class AuthService : IAuthService
{
    private readonly PosDbContext _db;
    private readonly IJwtTokenService _jwt;

    public AuthService(PosDbContext db, IJwtTokenService jwt)
    {
        _db = db;
        _jwt = jwt;
    }

    public async Task<LoginResponse> LoginAsync(LoginRequest request)
    {
        // Login bypasses the tenant filter - user doesn't know their RestaurantId yet,
        // so we look up globally by email then derive tenant from the loaded user.
        var user = await _db.Users
            .IgnoreQueryFilters()
            .Include(u => u.Restaurant)
            .FirstOrDefaultAsync(u => u.Email == request.Email);

        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new AppException("Invalid credentials.", 401);

        if (!user.IsActive)
            throw new AppException("Account is disabled.", 401);

        if (!user.Restaurant.IsActive)
            throw new AppException("Restaurant is disabled.", 401);

        var token = _jwt.Issue(user);
        return new LoginResponse(
            token, user.Id, user.FullName, user.Email, user.Role,
            user.Restaurant.Id, user.Restaurant.Name, user.Restaurant.Slug);
    }
}
