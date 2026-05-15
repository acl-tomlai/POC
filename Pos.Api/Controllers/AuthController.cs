using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;

    public AuthController(IAuthService auth)
    {
        _auth = auth;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request) =>
        Ok(await _auth.LoginAsync(request));
}
