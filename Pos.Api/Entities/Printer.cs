namespace Pos.Api.Entities;

public class Printer
{
    public Guid Id { get; set; }
    public Guid RestaurantId { get; set; }
    public Guid StoreId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string IpAddress { get; set; } = string.Empty;
    public int Port { get; set; }
    public string PrinterType { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }

    public Restaurant Restaurant { get; set; } = null!;
    public Store Store { get; set; } = null!;
}
