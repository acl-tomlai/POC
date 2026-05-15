using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pos.Api.DTOs;
using Pos.Api.Helpers;
using Pos.Api.Services;

namespace Pos.Api.Controllers;

[ApiController]
[Route("api/categories")]
[Authorize]
public class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categories;

    public CategoriesController(ICategoryService categories)
    {
        _categories = categories;
    }

    [HttpGet]
    public async Task<ActionResult<List<CategoryResponse>>> List() =>
        Ok(await _categories.ListAsync());

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CategoryResponse>> Get(Guid id) =>
        Ok(await _categories.GetAsync(id));

    [HttpPost]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<ActionResult<CategoryResponse>> Create([FromBody] CategoryCreateRequest request) =>
        Ok(await _categories.CreateAsync(request));

    [HttpPut("{id:guid}")]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<ActionResult<CategoryResponse>> Update(Guid id, [FromBody] CategoryUpdateRequest request) =>
        Ok(await _categories.UpdateAsync(id, request));

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.AdminOrManager)]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _categories.DeleteAsync(id);
        return NoContent();
    }
}
