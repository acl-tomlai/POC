using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Route("api/orders/{orderId:guid}/payments")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _payments;

    public PaymentsController(IPaymentService payments)
    {
        _payments = payments;
    }

    [HttpGet]
    public async Task<ActionResult<List<PaymentResponse>>> List(Guid orderId) =>
        Ok(await _payments.ListByOrderAsync(orderId));

    [HttpPost]
    public async Task<ActionResult<PaymentResponse>> Create(Guid orderId, [FromBody] PaymentCreateRequest request) =>
        Ok(await _payments.CreateAsync(orderId, request));
}
