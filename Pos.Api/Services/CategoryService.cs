using Microsoft.EntityFrameworkCore;
using Pos.Api.Data;
using Pos.Api.DTOs;
using Pos.Api.Entities;
using Pos.Api.Helpers;
using Pos.Api.Tenancy;

namespace Pos.Api.Services;

public interface ICategoryService
{
    Task<List<CategoryResponse>> ListAsync();
    Task<CategoryResponse> GetAsync(Guid id);
    Task<CategoryResponse> CreateAsync(CategoryCreateRequest request);
    Task<CategoryResponse> UpdateAsync(Guid id, CategoryUpdateRequest request);
    Task DeleteAsync(Guid id);
}

public class CategoryService : ICategoryService
{
    private readonly PosDbContext _db;
    private readonly ITenantContext _tenant;

    public CategoryService(PosDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<List<CategoryResponse>> ListAsync() =>
        await _db.Categories
            .OrderBy(c => c.DisplayOrder).ThenBy(c => c.Name)
            .Select(c => new CategoryResponse(
                c.Id, c.Name, c.NameLocalized, c.AltLanguageCode,
                c.DisplayOrder, c.IsActive, c.CreatedAt))
            .ToListAsync();

    public async Task<CategoryResponse> GetAsync(Guid id)
    {
        var c = await _db.Categories.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Category not found.");
        return ToResponse(c);
    }

    public async Task<CategoryResponse> CreateAsync(CategoryCreateRequest request)
    {
        var c = new Category
        {
            Id = Guid.NewGuid(),
            RestaurantId = _tenant.RequireRestaurantId(),
            Name = request.Name.Trim(),
            NameLocalized = NormalizeLocalizedName(request.NameLocalized),
            AltLanguageCode = NormalizeLanguageCode(request.AltLanguageCode),
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };
        _db.Categories.Add(c);
        await _db.SaveChangesAsync();
        return ToResponse(c);
    }

    public async Task<CategoryResponse> UpdateAsync(Guid id, CategoryUpdateRequest request)
    {
        var c = await _db.Categories.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Category not found.");
        c.Name = request.Name.Trim();
        c.NameLocalized = NormalizeLocalizedName(request.NameLocalized);
        c.AltLanguageCode = NormalizeLanguageCode(request.AltLanguageCode);
        c.DisplayOrder = request.DisplayOrder;
        c.IsActive = request.IsActive;
        await _db.SaveChangesAsync();
        return ToResponse(c);
    }

    private static string? NormalizeLocalizedName(string? value)
    {
        var t = value?.Trim();
        return string.IsNullOrEmpty(t) ? null : t;
    }

    private static string? NormalizeLanguageCode(string? value)
    {
        var t = value?.Trim().ToLowerInvariant();
        return string.IsNullOrEmpty(t) ? null : t;
    }

    public async Task DeleteAsync(Guid id)
    {
        var c = await _db.Categories.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new NotFoundException("Category not found.");
        var hasProducts = await _db.Products.AnyAsync(p => p.CategoryId == id);
        if (hasProducts)
            throw new ConflictException("Category has products and cannot be deleted.");
        _db.Categories.Remove(c);
        await _db.SaveChangesAsync();
    }

    private static CategoryResponse ToResponse(Category c) =>
        new(c.Id, c.Name, c.NameLocalized, c.AltLanguageCode,
            c.DisplayOrder, c.IsActive, c.CreatedAt);
}
