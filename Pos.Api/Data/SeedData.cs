using Microsoft.EntityFrameworkCore;
using Pos.Api.Entities;
using Pos.Api.Helpers;

namespace Pos.Api.Data;

// Runtime seeding (not HasData) - BCrypt hashes are non-deterministic, so we hash at runtime.
// Idempotent: only inserts if the demo restaurant doesn't already exist.
public static class SeedData
{
    public static readonly Guid RestaurantId = new("11111111-1111-1111-1111-111111111111");
    public static readonly Guid AdminUserId  = new("22222222-2222-2222-2222-222222222222");
    public static readonly Guid StoreId      = new("33333333-3333-3333-3333-333333333333");

    public static async Task ApplyAsync(PosDbContext db)
    {
        // Bypass tenant filter - we're seeding before any tenant context exists.
        var exists = await db.Restaurants
            .IgnoreQueryFilters()
            .AnyAsync(r => r.Id == RestaurantId);
        if (exists) return;

        var now = DateTime.UtcNow;

        var restaurant = new Restaurant
        {
            Id = RestaurantId,
            Name = "Demo Restaurant Co.",
            Slug = "demo",
            ContactEmail = "admin@pos.local",
            IsActive = true,
            CreatedAt = now
        };

        var admin = new User
        {
            Id = AdminUserId,
            RestaurantId = RestaurantId,
            FullName = "Demo Admin",
            Email = "admin@pos.local",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
            Role = Roles.Admin,
            IsActive = true,
            CreatedAt = now
        };

        var store = new Store
        {
            Id = StoreId,
            RestaurantId = RestaurantId,
            Name = "Main Store",
            IsActive = true,
            CreatedAt = now
        };

        var catDrinks = new Category { Id = Guid.NewGuid(), RestaurantId = RestaurantId, Name = "Drinks", DisplayOrder = 1, IsActive = true, CreatedAt = now };
        var catFood   = new Category { Id = Guid.NewGuid(), RestaurantId = RestaurantId, Name = "Food",   DisplayOrder = 2, IsActive = true, CreatedAt = now };
        var catSnacks = new Category { Id = Guid.NewGuid(), RestaurantId = RestaurantId, Name = "Snacks", DisplayOrder = 3, IsActive = true, CreatedAt = now };

        var products = new[]
        {
            new Product { Id = Guid.NewGuid(), RestaurantId = RestaurantId, CategoryId = catDrinks.Id, Name = "Coffee",   Price = 4.50m, IsActive = true, CreatedAt = now },
            new Product { Id = Guid.NewGuid(), RestaurantId = RestaurantId, CategoryId = catDrinks.Id, Name = "Tea",      Price = 3.50m, IsActive = true, CreatedAt = now },
            new Product { Id = Guid.NewGuid(), RestaurantId = RestaurantId, CategoryId = catFood.Id,   Name = "Sandwich", Price = 8.90m, IsActive = true, CreatedAt = now },
            new Product { Id = Guid.NewGuid(), RestaurantId = RestaurantId, CategoryId = catSnacks.Id, Name = "Muffin",   Price = 4.00m, IsActive = true, CreatedAt = now },
        };

        var printer = new Printer
        {
            Id = Guid.NewGuid(),
            RestaurantId = RestaurantId,
            StoreId = StoreId,
            Name = "Front Counter Printer",
            IpAddress = "192.168.1.50",
            Port = 9100,
            PrinterType = "ESC/POS",
            IsActive = true,
            CreatedAt = now
        };

        db.Restaurants.Add(restaurant);
        db.Users.Add(admin);
        db.Stores.Add(store);
        db.Categories.AddRange(catDrinks, catFood, catSnacks);
        db.Products.AddRange(products);
        db.Printers.Add(printer);

        await db.SaveChangesAsync();
    }
}
