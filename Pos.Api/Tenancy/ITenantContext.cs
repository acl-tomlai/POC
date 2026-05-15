namespace Pos.Api.Tenancy;

public interface ITenantContext
{
    Guid? CurrentRestaurantId { get; }
    Guid? CurrentUserId { get; }
    string? CurrentUserRole { get; }
    bool HasTenant { get; }

    void SetTenant(Guid restaurantId, Guid userId, string role);
    Guid RequireRestaurantId();
    Guid RequireUserId();
}
