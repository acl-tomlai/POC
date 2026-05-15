using System.Security.Claims;

namespace Pos.Api.Tenancy;

// Reads the restaurant_id / sub / role claims from the authenticated principal
// and pins them onto the request-scoped ITenantContext. Must run AFTER UseAuthentication.
public class TenantContextMiddleware
{
    private readonly RequestDelegate _next;

    public TenantContextMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ITenantContext tenantContext)
    {
        var user = context.User;
        if (user?.Identity?.IsAuthenticated == true)
        {
            var restaurantIdStr = user.FindFirst(TenantClaims.RestaurantId)?.Value;
            var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                            ?? user.FindFirst("sub")?.Value;
            var role = user.FindFirst(ClaimTypes.Role)?.Value
                       ?? user.FindFirst("role")?.Value
                       ?? string.Empty;

            if (Guid.TryParse(restaurantIdStr, out var restaurantId) &&
                Guid.TryParse(userIdStr, out var userId))
            {
                tenantContext.SetTenant(restaurantId, userId, role);
            }
        }

        await _next(context);
    }
}
