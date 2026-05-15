namespace Pos.Api.Entities;

public class Category
{
    public Guid Id { get; set; }
    public Guid RestaurantId { get; set; }
    public string Name { get; set; } = string.Empty;
    /// <summary>
    /// Optional alternative-language category name (e.g. Vietnamese). Used by
    /// surfaces that opt into "vi" or "both" rendering.
    /// </summary>
    public string? NameLocalized { get; set; }
    /// <summary>ISO-639-1 code of <see cref="NameLocalized"/> (e.g. "vi").</summary>
    public string? AltLanguageCode { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }

    public Restaurant Restaurant { get; set; } = null!;
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
