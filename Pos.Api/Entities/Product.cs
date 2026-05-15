namespace Pos.Api.Entities;

public class Product
{
    public Guid Id { get; set; }
    public Guid RestaurantId { get; set; }
    public Guid CategoryId { get; set; }
    public string Name { get; set; } = string.Empty;
    /// <summary>
    /// Optional alternative-language name (typically Vietnamese for the kitchen).
    /// Surfaces on kitchen tickets / receipts / customer display when the till
    /// is configured for "vi" or "both" on that surface.
    /// </summary>
    public string? NameLocalized { get; set; }
    /// <summary>
    /// ISO-639-1 code of <see cref="NameLocalized"/> (e.g. "vi"). Null when no
    /// alt name is set.
    /// </summary>
    public string? AltLanguageCode { get; set; }
    public string? Description { get; set; }
    public string? Sku { get; set; }
    public string? Barcode { get; set; }
    public decimal Price { get; set; }
    public decimal? CostPrice { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }

    public Restaurant Restaurant { get; set; } = null!;
    public Category Category { get; set; } = null!;
    public ICollection<OrderLine> OrderLines { get; set; } = new List<OrderLine>();
}
