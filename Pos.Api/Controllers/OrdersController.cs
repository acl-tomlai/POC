using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Route("api/orders")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orders;

    public OrdersController(IOrderService orders)
    {
        _orders = orders;
    }

    [HttpGet]
    public async Task<ActionResult<List<OrderResponse>>> List() =>
        Ok(await _orders.ListAsync());

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<OrderResponse>> Get(Guid id) =>
        Ok(await _orders.GetAsync(id));

    [HttpPost]
    public async Task<ActionResult<OrderResponse>> Create([FromBody] OrderCreateRequest request) =>
        Ok(await _orders.CreateAsync(request));

    [HttpPut("{id:guid}/status")]
    public async Task<ActionResult<OrderResponse>> UpdateStatus(Guid id, [FromBody] OrderStatusUpdateRequest request) =>
        Ok(await _orders.UpdateStatusAsync(id, request.Status));
}
