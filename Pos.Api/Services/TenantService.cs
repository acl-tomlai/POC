using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface ITenantService
{
    Task<LoginResponse> SignupAsync(TenantSignupRequest request);
    Task<TenantResponse> GetCurrentAsync();
    Task<TenantResponse> UpdateCurrentAsync(TenantUpdateRequest request);
}

public class TenantService : ITenantService
{
    private readonly PosDbContext _db;
    private readonly IJwtTokenService _jwt;
    private readonly ITenantContext _tenant;

    public TenantService(PosDbContext db, IJwtTokenService jwt, ITenantContext tenant)
    {
        _db = db;
        _jwt = jwt;
        _tenant = tenant;
    }

    public async Task<LoginResponse> SignupAsync(TenantSignupRequest request)
    {
        var slug = request.Restaurant.Slug.Trim().ToLowerInvariant();
        if (!SlugRules.IsValid(slug, out var slugError))
            throw new AppException(slugError!);

        // Signup bypasses the tenant filter - no tenant exists yet.
        var slugTaken = await _db.Restaurants
            .IgnoreQueryFilters()
            .AnyAsync(r => r.Slug == slug);
        if (slugTaken)
            throw new ConflictException("Slug is already taken.");

        var now = DateTime.UtcNow;
        var restaurant = new Restaurant
        {
            Id = Guid.NewGuid(),
            Name = request.Restaurant.Name.Trim(),
            Slug = slug,
            ContactEmail = request.Restaurant.ContactEmail.Trim(),
            Phone = request.Restaurant.Phone?.Trim(),
            IsActive = true,
            CreatedAt = now
        };

        var admin = new User
        {
            Id = Guid.NewGuid(),
            RestaurantId = restaurant.Id,
            FullName = request.Admin.FullName.Trim(),
            Email = request.Admin.Email.Trim(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Admin.Password),
            Role = Roles.Admin,
            IsActive = true,
            CreatedAt = now
        };

        // Create both atomically. EF will wrap this in a transaction via SaveChanges.
        _db.Restaurants.Add(restaurant);
        _db.Users.Add(admin);
        await _db.SaveChangesAsync();

        var token = _jwt.Issue(admin);
        return new LoginResponse(
            token, admin.Id, admin.FullName, admin.Email, admin.Role,
            restaurant.Id, restaurant.Name, restaurant.Slug);
    }

    public async Task<TenantResponse> GetCurrentAsync()
    {
        var id = _tenant.RequireRestaurantId();
        var r = await _db.Restaurants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Restaurant not found.");
        return ToResponse(r);
    }

    public async Task<TenantResponse> UpdateCurrentAsync(TenantUpdateRequest request)
    {
        var id = _tenant.RequireRestaurantId();
        var r = await _db.Restaurants
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Restaurant not found.");

        r.Name = request.Name.Trim();
        r.ContactEmail = request.ContactEmail.Trim();
        r.Phone = request.Phone?.Trim();
        await _db.SaveChangesAsync();
        return ToResponse(r);
    }

    private static TenantResponse ToResponse(Restaurant r) =>
        new(r.Id, r.Name, r.Slug, r.ContactEmail, r.Phone, r.IsActive, r.CreatedAt);
}
