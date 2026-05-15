using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Helpers;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Route("api/users")]
[Authorize(Roles = Roles.AdminOnly)]
public class UsersController : ControllerBase
{
    private readonly IUserService _users;

    public UsersController(IUserService users)
    {
        _users = users;
    }

    [HttpGet]
    public async Task<ActionResult<List<UserResponse>>> List() =>
        Ok(await _users.ListAsync());

    [HttpPost]
    public async Task<ActionResult<UserResponse>> Create([FromBody] UserCreateRequest request) =>
        Ok(await _users.CreateAsync(request));

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<UserResponse>> Update(Guid id, [FromBody] UserUpdateRequest request) =>
        Ok(await _users.UpdateAsync(id, request));

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _users.DeleteAsync(id);
        return NoContent();
    }
}
