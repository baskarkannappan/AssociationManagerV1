using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AssetsController : ControllerBase
{
    private readonly IAssetService _assetService;
    private readonly IAuditService _auditService;

    public AssetsController(IAssetService assetService, IAuditService auditService)
    {
        _assetService = assetService;
        _auditService = auditService;
    }

    [HttpGet("hierarchy")]
    public async Task<IActionResult> GetHierarchy()
    {
        var hierarchy = await _assetService.GetHierarchyAsync();
        return Ok(hierarchy);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var asset = await _assetService.GetByIdAsync(id);
        if (asset == null) return NotFound();
        return Ok(asset);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Asset asset)
    {
        var id = await _assetService.CreateAsync(asset);
        await _auditService.LogAsync("Create Asset", "Asset", id);
        return CreatedAtAction(nameof(GetById), new { id }, asset);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] Asset asset)
    {
        asset.AssetId = id;
        var success = await _assetService.UpdateAsync(asset);
        if (!success) return NotFound();
        await _auditService.LogAsync("Update Asset", "Asset", id);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _assetService.DeleteAsync(id);
        if (!success) return NotFound();
        await _auditService.LogAsync("Delete Asset", "Asset", id);
        return NoContent();
    }
}
