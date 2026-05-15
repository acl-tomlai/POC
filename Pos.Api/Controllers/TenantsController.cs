using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Pos.Api.DTOs;
using Pos.Api.Helpers;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

public class TenancyOptions
{
    public string? SignupKey { get; set; }
}

[ApiController]
[Route("api/tenants")]
public class TenantsController : ControllerBase
{
    private readonly ITenantService _tenants;
    private readonly TenancyOptions _options;

    public TenantsController(ITenantService tenants, IOptions<TenancyOptions> options)
    {
        _tenants = tenants;
        _options = options.Value;
    }

    [HttpPost("signup")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponse>> Signup([FromBody] TenantSignupRequest request)
    {
        // Optional shared-secret gate. If SignupKey is empty, signup is open.
        if (!string.IsNullOrEmpty(_options.SignupKey))
        {
            var supplied = Request.Headers["X-Signup-Key"].ToString();
            if (!string.Equals(supplied, _options.SignupKey, StringComparison.Ordinal))
                throw new ForbiddenException("Invalid signup key.");
        }

        var result = await _tenants.SignupAsync(request);
        return Ok(result);
    }

    [HttpGet("me")]
    [Authorize(Roles = Roles.AllRoles)]
    public async Task<ActionResult<TenantResponse>> Me() =>
        Ok(await _tenants.GetCurrentAsync());

    [HttpPut("me")]
    [Authorize(Roles = Roles.AdminOnly)]
    public async Task<ActionResult<TenantResponse>> Update([FromBody] TenantUpdateRequest request) =>
        Ok(await _tenants.UpdateCurrentAsync(request));
}
