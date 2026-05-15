using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Helpers;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Route("api/products")]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly IProductService _products;

    public ProductsController(IProductService products)
    {
        _products = products;
    }

    [HttpGet]
    public async Task<ActionResult<List<ProductResponse>>> List() =>
        Ok(await _products.ListAsync());

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProductResponse>> Get(Guid id) =>
        Ok(await _products.GetAsync(id));

    [HttpGet("barcode/{barcode}")]
    public async Task<ActionResult<ProductResponse>> GetByBarcode(string barcode)
    {
        var product = await _products.GetByBarcodeAsync(barcode);
        return product is null ? NotFound() : Ok(product);
    }

    [HttpPost]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<ActionResult<ProductResponse>> Create([FromBody] ProductCreateRequest request) =>
        Ok(await _products.CreateAsync(request));

    [HttpPut("{id:guid}")]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<ActionResult<ProductResponse>> Update(Guid id, [FromBody] ProductUpdateRequest request) =>
        Ok(await _products.UpdateAsync(id, request));

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _products.DeleteAsync(id);
        return NoContent();
    }
}
