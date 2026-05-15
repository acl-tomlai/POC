using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface IUserService
{
    Task<List<UserResponse>> ListAsync();
    Task<UserResponse> CreateAsync(UserCreateRequest request);
    Task<UserResponse> UpdateAsync(Guid id, UserUpdateRequest request);
    Task DeleteAsync(Guid id);
}

public class UserService : IUserService
{
    private static readonly HashSet<string> ManageableRoles = new(StringComparer.OrdinalIgnoreCase)
    {
        Roles.Admin, Roles.Manager, Roles.Cashier
    };

    private readonly PosDbContext _db;
    private readonly ITenantContext _tenant;

    public UserService(PosDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<List<UserResponse>> ListAsync()
    {
        return await _db.Users
            .OrderBy(u => u.FullName)
            .Select(u => new UserResponse(u.Id, u.FullName, u.Email, u.Role, u.IsActive, u.CreatedAt))
            .ToListAsync();
    }

    public async Task<UserResponse> CreateAsync(UserCreateRequest request)
    {
        var role = NormalizeRole(request.Role);
        var restaurantId = _tenant.RequireRestaurantId();

        var emailTaken = await _db.Users.AnyAsync(u => u.Email == request.Email);
        if (emailTaken)
            throw new ConflictException("Email already exists in this restaurant.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            RestaurantId = restaurantId,
            FullName = request.FullName.Trim(),
            Email = request.Email.Trim(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = role,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return ToResponse(user);
    }

    public async Task<UserResponse> UpdateAsync(Guid id, UserUpdateRequest request)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id)
            ?? throw new NotFoundException("User not found.");
        user.FullName = request.FullName.Trim();
        user.Role = NormalizeRole(request.Role);
        user.IsActive = request.IsActive;
        await _db.SaveChangesAsync();
        return ToResponse(user);
    }

    public async Task DeleteAsync(Guid id)
    {
        if (id == _tenant.RequireUserId())
            throw new AppException("Cannot disable your own account.");
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id)
            ?? throw new NotFoundException("User not found.");
        user.IsActive = false;
        await _db.SaveChangesAsync();
    }

    private static string NormalizeRole(string role)
    {
        if (!ManageableRoles.Contains(role))
            throw new AppException($"Invalid role. Allowed: {string.Join(", ", ManageableRoles)}.");
        return role;
    }

    private static UserResponse ToResponse(User u) =>
        new(u.Id, u.FullName, u.Email, u.Role, u.IsActive, u.CreatedAt);
}
