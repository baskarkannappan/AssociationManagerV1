using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
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
        return Ok(ApiResponse<IEnumerable<Asset>>.SuccessResponse(hierarchy));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var asset = await _assetService.GetByIdAsync(id);
        if (asset == null) return NotFound(ApiResponse.FailureResponse("Asset not found."));
        return Ok(ApiResponse<Asset>.SuccessResponse(asset));
    }

    [HttpPost]
    [RequireRole(AppRole.AssetManager, AppRole.AssociationAdmin)]
    public async Task<IActionResult> Create([FromBody] Asset asset)
    {
        var id = await _assetService.CreateAsync(asset);
        await _auditService.LogAsync("Create Asset", "Asset", id);
        return CreatedAtAction(nameof(GetById), new { id }, ApiResponse<int>.SuccessResponse(id, "Asset created successfully."));
    }

    [HttpPost("bulk")]
    [RequireRole(AppRole.AssetManager, AppRole.AssociationAdmin)]
    public async Task<IActionResult> BulkCreate([FromBody] BulkCreateRequest request)
    {
        var count = await _assetService.BulkCreateAsync(request);
        await _auditService.LogAsync("Bulk Create Assets", "Asset", 0);
        return Ok(ApiResponse<int>.SuccessResponse(count, $"{count} assets created in bulk."));
    }

    [HttpPut("{id}")]
    [RequireRole(AppRole.AssetManager, AppRole.AssociationAdmin)]
    public async Task<IActionResult> Update(int id, [FromBody] Asset asset)
    {
        asset.AssetId = id;
        var success = await _assetService.UpdateAsync(asset);
        if (!success) return NotFound(ApiResponse.FailureResponse("Asset not found for update."));
        await _auditService.LogAsync("Update Asset", "Asset", id);
        return Ok(ApiResponse.SuccessResponse("Asset updated successfully."));
    }

    [HttpDelete("{id}")]
    [RequireRole(AppRole.AssetManager, AppRole.AssociationAdmin)]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _assetService.DeleteAsync(id);
        if (!success) return NotFound(ApiResponse.FailureResponse("Asset not found for deletion."));
        await _auditService.LogAsync("Delete Asset", "Asset", id);
        return Ok(ApiResponse.SuccessResponse("Asset deleted successfully."));
    }
}
