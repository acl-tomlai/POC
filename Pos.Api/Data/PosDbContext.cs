using Microsoft.EntityFrameworkCore;
using Pos.Api.Entities;
using Pos.Api.Tenancy;

namespace Pos.Api.Data;

public class PosDbContext : DbContext
{
    private readonly ITenantContext _tenant;

    public PosDbContext(DbContextOptions<PosDbContext> options, ITenantContext tenant)
        : base(options)
    {
        _tenant = tenant;
    }

    public DbSet<Restaurant> Restaurants => Set<Restaurant>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Store> Stores => Set<Store>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderLine> OrderLines => Set<OrderLine>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Printer> Printers => Set<Printer>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        base.OnModelCreating(mb);

        // ---------- Restaurant (tenant root, not filtered) ----------
        mb.Entity<Restaurant>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.Property(x => x.Slug).IsRequired().HasMaxLength(40);
            e.Property(x => x.ContactEmail).IsRequired().HasMaxLength(256);
            e.Property(x => x.Phone).HasMaxLength(50);
            e.HasIndex(x => x.Slug).IsUnique();
        });

        // ---------- User ----------
        mb.Entity<User>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.FullName).IsRequired().HasMaxLength(200);
            e.Property(x => x.Email).IsRequired().HasMaxLength(256);
            e.Property(x => x.PasswordHash).IsRequired();
            e.Property(x => x.Role).IsRequired().HasMaxLength(50);
            e.HasIndex(x => new { x.RestaurantId, x.Email }).IsUnique();
            e.HasOne(x => x.Restaurant).WithMany(r => r.Users)
                .HasForeignKey(x => x.RestaurantId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });

        // ---------- Store ----------
        mb.Entity<Store>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.Property(x => x.Address).HasMaxLength(500);
            e.Property(x => x.Phone).HasMaxLength(50);
            e.HasIndex(x => x.RestaurantId);
            e.HasOne(x => x.Restaurant).WithMany(r => r.Stores)
                .HasForeignKey(x => x.RestaurantId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });

        // ---------- Category ----------
        mb.Entity<Category>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.Property(x => x.NameLocalized).HasMaxLength(200);
            e.Property(x => x.AltLanguageCode).HasMaxLength(8);
            e.HasIndex(x => x.RestaurantId);
            e.HasOne(x => x.Restaurant).WithMany(r => r.Categories)
                .HasForeignKey(x => x.RestaurantId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });

        // ---------- Product ----------
        mb.Entity<Product>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.Property(x => x.NameLocalized).HasMaxLength(200);
            e.Property(x => x.AltLanguageCode).HasMaxLength(8);
            e.Property(x => x.Description).HasMaxLength(2000);
            e.Property(x => x.Sku).HasMaxLength(100);
            e.Property(x => x.Barcode).HasMaxLength(100);
            e.Property(x => x.ImageUrl).HasMaxLength(1000);
            e.Property(x => x.Price).HasPrecision(18, 2);
            e.Property(x => x.CostPrice).HasPrecision(18, 2);
            e.HasIndex(x => x.RestaurantId);
            e.HasIndex(x => new { x.RestaurantId, x.Barcode });
            e.HasOne(x => x.Restaurant).WithMany(r => r.Products)
                .HasForeignKey(x => x.RestaurantId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Category).WithMany(c => c.Products)
                .HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });

        // ---------- Order ----------
        mb.Entity<Order>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.OrderNumber).IsRequired().HasMaxLength(50);
            e.Property(x => x.Status).IsRequired().HasMaxLength(50);
            e.Property(x => x.PaymentStatus).IsRequired().HasMaxLength(50);
            e.Property(x => x.Subtotal).HasPrecision(18, 2);
            e.Property(x => x.TaxAmount).HasPrecision(18, 2);
            e.Property(x => x.DiscountAmount).HasPrecision(18, 2);
            e.Property(x => x.TotalAmount).HasPrecision(18, 2);
            e.HasIndex(x => new { x.RestaurantId, x.OrderNumber }).IsUnique();
            e.HasOne(x => x.Restaurant).WithMany(r => r.Orders)
                .HasForeignKey(x => x.RestaurantId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Store).WithMany(s => s.Orders)
                .HasForeignKey(x => x.StoreId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.CreatedByUser).WithMany()
                .HasForeignKey(x => x.CreatedByUserId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });

        // ---------- OrderLine ----------
        mb.Entity<OrderLine>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.ProductName).IsRequired().HasMaxLength(200);
            e.Property(x => x.Quantity).HasPrecision(18, 3);
            e.Property(x => x.UnitPrice).HasPrecision(18, 2);
            e.Property(x => x.DiscountAmount).HasPrecision(18, 2);
            e.Property(x => x.LineTotal).HasPrecision(18, 2);
            e.HasIndex(x => x.RestaurantId);
            e.HasOne(x => x.Order).WithMany(o => o.OrderLines)
                .HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Product).WithMany(p => p.OrderLines)
                .HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });

        // ---------- Payment ----------
        mb.Entity<Payment>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.PaymentMethod).IsRequired().HasMaxLength(50);
            e.Property(x => x.Amount).HasPrecision(18, 2);
            e.Property(x => x.Reference).HasMaxLength(200);
            e.HasIndex(x => x.RestaurantId);
            e.HasOne(x => x.Order).WithMany(o => o.Payments)
                .HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });

        // ---------- Printer ----------
        mb.Entity<Printer>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(200);
            e.Property(x => x.IpAddress).IsRequired().HasMaxLength(45);
            e.Property(x => x.PrinterType).IsRequired().HasMaxLength(50);
            e.HasIndex(x => x.RestaurantId);
            e.HasOne(x => x.Restaurant).WithMany()
                .HasForeignKey(x => x.RestaurantId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Store).WithMany(s => s.Printers)
                .HasForeignKey(x => x.StoreId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.RestaurantId == _tenant.CurrentRestaurantId);
        });
    }
}
