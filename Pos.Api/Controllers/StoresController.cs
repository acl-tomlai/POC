using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Helpers;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Route("api/stores")]
[Authorize]
public class StoresController : ControllerBase
{
    private readonly IStoreService _stores;

    public StoresController(IStoreService stores)
    {
        _stores = stores;
    }

    [HttpGet]
    public async Task<ActionResult<List<StoreResponse>>> List() =>
        Ok(await _stores.ListAsync());

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<StoreResponse>> Get(Guid id) =>
        Ok(await _stores.GetAsync(id));

    [HttpPost]
    [Authorize(Roles = Roles.AdminOnly)]
    public async Task<ActionResult<StoreResponse>> Create([FromBody] StoreCreateRequest request) =>
        Ok(await _stores.CreateAsync(request));

    [HttpPut("{id:guid}")]
    [Authorize(Roles = Roles.AdminOnly)]
    public async Task<ActionResult<StoreResponse>> Update(Guid id, [FromBody] StoreUpdateRequest request) =>
        Ok(await _stores.UpdateAsync(id, request));
}
