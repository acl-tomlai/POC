namespace Pos.Api.Tenancy;

public class TenantContext : ITenantContext
{
    public Guid? CurrentRestaurantId { get; private set; }
    public Guid? CurrentUserId { get; private set; }
    public string? CurrentUserRole { get; private set; }
    public bool HasTenant => CurrentRestaurantId.HasValue;

    private bool _locked;

    public void SetTenant(Guid restaurantId, Guid userId, string role)
    {
        // Tenant value must be immutable per request once set.
        if (_locked)
            throw new InvalidOperationException("Tenant context has already been set for this request.");

        CurrentRestaurantId = restaurantId;
        CurrentUserId = userId;
        CurrentUserRole = role;
        _locked = true;
    }

    public Guid RequireRestaurantId() =>
        CurrentRestaurantId ?? throw new InvalidOperationException("No tenant in scope on this request.");

    public Guid RequireUserId() =>
        CurrentUserId ?? throw new InvalidOperationException("No user in scope on this request.");
}
