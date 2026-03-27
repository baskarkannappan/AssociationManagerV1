using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AssetsController : ControllerBase
{
    private readonly IAssetService _assetService;
    private readonly IAuditService _auditService;
    private readonly AssociationManager.Shared.Interfaces.ITenantContext _tenantContext;
    private readonly IRuleEngineService _ruleEngine;

    public AssetsController(IAssetService assetService, IAuditService auditService, AssociationManager.Shared.Interfaces.ITenantContext tenantContext, IRuleEngineService ruleEngine)
    {
        _assetService = assetService;
        _auditService = auditService;
        _tenantContext = tenantContext;
        _ruleEngine = ruleEngine;
    }

    [HttpGet("hierarchy")]
    public async Task<IActionResult> GetHierarchy()
    {
        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", User.FindAll(System.Security.Claims.ClaimTypes.Role).Select(c => c.Value)),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId
        };

        // If the user is a Resident (or lower), only show their owned/occupied assets
        bool isResidentOnly = await _ruleEngine.EvaluateRuleAsync("IsResident", securityContext);
        int? filterUserId = isResidentOnly ? _tenantContext.UserId : null;
        
        var hierarchy = await _assetService.GetHierarchyAsync(filterUserId);
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
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> Create([FromBody] Asset asset)
    {
        var id = await _assetService.CreateAsync(asset);
        await _auditService.LogAsync("Create Asset", "Asset", id);
        return CreatedAtAction(nameof(GetById), new { id }, ApiResponse<int>.SuccessResponse(id, "Asset created successfully."));
    }

    [HttpPost("bulk")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> BulkCreate([FromBody] BulkCreateRequest request)
    {
        var count = await _assetService.BulkCreateAsync(request);
        await _auditService.LogAsync("Bulk Create Assets", "Asset", 0);
        return Ok(ApiResponse<int>.SuccessResponse(count, $"{count} assets created in bulk."));
    }

    [HttpPut("{id}")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> Update(int id, [FromBody] Asset asset)
    {
        asset.AssetId = id;
        var success = await _assetService.UpdateAsync(asset);
        if (!success) return NotFound(ApiResponse.FailureResponse("Asset not found for update."));
        await _auditService.LogAsync("Update Asset", "Asset", id);
        return Ok(ApiResponse.SuccessResponse("Asset updated successfully."));
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _assetService.DeleteAsync(id);
        if (!success) return NotFound(ApiResponse.FailureResponse("Asset not found for deletion."));
        await _auditService.LogAsync("Delete Asset", "Asset", id);
        return Ok(ApiResponse.SuccessResponse("Asset deleted successfully."));
    }
}
