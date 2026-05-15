using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface IProductService
{
    Task<List<ProductResponse>> ListAsync();
    Task<ProductResponse> GetAsync(Guid id);
    Task<ProductResponse?> GetByBarcodeAsync(string barcode);
    Task<ProductResponse> CreateAsync(ProductCreateRequest request);
    Task<ProductResponse> UpdateAsync(Guid id, ProductUpdateRequest request);
    Task DeleteAsync(Guid id);
}

public class ProductService : IProductService
{
    private readonly PosDbContext _db;
    private readonly ITenantContext _tenant;

    public ProductService(PosDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    private IQueryable<Product> WithCategory() =>
        _db.Products.Include(p => p.Category);

    public async Task<List<ProductResponse>> ListAsync() =>
        await WithCategory()
            .OrderBy(p => p.Name)
            .Select(p => ToResponse(p))
            .ToListAsync();

    public async Task<ProductResponse> GetAsync(Guid id)
    {
        var p = await WithCategory().FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Product not found.");
        return ToResponse(p);
    }

    public async Task<ProductResponse?> GetByBarcodeAsync(string barcode)
    {
        var p = await WithCategory().FirstOrDefaultAsync(x => x.Barcode == barcode);
        return p is null ? null : ToResponse(p);
    }

    public async Task<ProductResponse> CreateAsync(ProductCreateRequest request)
    {
        var restaurantId = _tenant.RequireRestaurantId();

        // Cross-tenant guard: category must belong to caller's tenant.
        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.CategoryId)
            ?? throw new AppException("CategoryId does not belong to your restaurant.");

        var p = new Product
        {
            Id = Guid.NewGuid(),
            RestaurantId = restaurantId,
            CategoryId = category.Id,
            Name = request.Name.Trim(),
            NameLocalized = NormalizeLocalizedName(request.NameLocalized),
            AltLanguageCode = NormalizeLanguageCode(request.AltLanguageCode),
            Description = request.Description,
            Sku = request.Sku,
            Barcode = request.Barcode,
            Price = request.Price,
            CostPrice = request.CostPrice,
            ImageUrl = request.ImageUrl,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            Category = category
        };
        _db.Products.Add(p);
        await _db.SaveChangesAsync();
        return ToResponse(p);
    }

    public async Task<ProductResponse> UpdateAsync(Guid id, ProductUpdateRequest request)
    {
        var p = await _db.Products.Include(x => x.Category)
            .FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Product not found.");

        if (p.CategoryId != request.CategoryId)
        {
            var newCategory = await _db.Categories.FirstOrDefaultAsync(c => c.Id == request.CategoryId)
                ?? throw new AppException("CategoryId does not belong to your restaurant.");
            p.CategoryId = newCategory.Id;
            p.Category = newCategory;
        }

        p.Name = request.Name.Trim();
        p.NameLocalized = NormalizeLocalizedName(request.NameLocalized);
        p.AltLanguageCode = NormalizeLanguageCode(request.AltLanguageCode);
        p.Description = request.Description;
        p.Sku = request.Sku;
        p.Barcode = request.Barcode;
        p.Price = request.Price;
        p.CostPrice = request.CostPrice;
        p.ImageUrl = request.ImageUrl;
        p.IsActive = request.IsActive;
        await _db.SaveChangesAsync();
        return ToResponse(p);
    }

    /// <summary>Trims whitespace; treats an empty result as null.</summary>
    private static string? NormalizeLocalizedName(string? value)
    {
        var t = value?.Trim();
        return string.IsNullOrEmpty(t) ? null : t;
    }

    /// <summary>Trims + lowercases ISO codes; empty becomes null.</summary>
    private static string? NormalizeLanguageCode(string? value)
    {
        var t = value?.Trim().ToLowerInvariant();
        return string.IsNullOrEmpty(t) ? null : t;
    }

    public async Task DeleteAsync(Guid id)
    {
        var p = await _db.Products.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Product not found.");
        var inUse = await _db.OrderLines.AnyAsync(l => l.ProductId == id);
        if (inUse)
        {
            // Soft-disable instead of hard-delete when product is referenced by orders.
            p.IsActive = false;
        }
        else
        {
            _db.Products.Remove(p);
        }
        await _db.SaveChangesAsync();
    }

    private static ProductResponse ToResponse(Product p) =>
        new(p.Id, p.CategoryId, p.Category?.Name ?? string.Empty, p.Name,
            p.NameLocalized, p.AltLanguageCode, p.Description,
            p.Sku, p.Barcode, p.Price, p.CostPrice, p.ImageUrl, p.IsActive, p.CreatedAt);
}
