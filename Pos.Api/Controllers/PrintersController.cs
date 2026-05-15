using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Helpers;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Authorize]
public class PrintersController : ControllerBase
{
    private readonly IPrinterService _printers;

    public PrintersController(IPrinterService printers)
    {
        _printers = printers;
    }

    [HttpGet("api/stores/{storeId:guid}/printers")]
    public async Task<ActionResult<List<PrinterResponse>>> ListByStore(Guid storeId) =>
        Ok(await _printers.ListByStoreAsync(storeId));

    [HttpGet("api/printers/{id:guid}")]
    public async Task<ActionResult<PrinterResponse>> Get(Guid id) =>
        Ok(await _printers.GetAsync(id));

    [HttpPost("api/printers")]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<ActionResult<PrinterResponse>> Create([FromBody] PrinterCreateRequest request) =>
        Ok(await _printers.CreateAsync(request));

    [HttpPut("api/printers/{id:guid}")]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<ActionResult<PrinterResponse>> Update(Guid id, [FromBody] PrinterUpdateRequest request) =>
        Ok(await _printers.UpdateAsync(id, request));

    [HttpDelete("api/printers/{id:guid}")]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _printers.DeleteAsync(id);
        return NoContent();
    }
}
