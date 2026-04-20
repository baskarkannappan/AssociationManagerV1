using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Linq;
using System.Threading.Tasks;
using Hangfire;

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
    private readonly IBackgroundJobClient _backgroundJobClient;

    public AssetsController(
        IAssetService assetService, 
        IAuditService auditService, 
        AssociationManager.Shared.Interfaces.ITenantContext tenantContext, 
        IRuleEngineService ruleEngine,
        IBackgroundJobClient backgroundJobClient)
    {
        _assetService = assetService;
        _auditService = auditService;
        _tenantContext = tenantContext;
        _ruleEngine = ruleEngine;
        _backgroundJobClient = backgroundJobClient;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var assets = await _assetService.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<Asset>>.SuccessResponse(assets));
    }

    [HttpGet("hierarchy")]
    public async Task<IActionResult> GetHierarchy([FromQuery] int? parentId = null)
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();
        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", User.FindAll(System.Security.Claims.ClaimTypes.Role).Select(c => c.Value)),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId
        };

        // If the user is a Resident (Level 10) AND NOT an Admin, only show their owned/occupied assets
        // If UserLevel > 10 (Admin, Manager), we always show the full hierarchy
        bool isResidentOnly = securityContext.UserLevel <= AppRole.LevelResident;
        int? filterUserId = isResidentOnly ? _tenantContext.UserId : null;
        
        var hierarchy = await _assetService.GetHierarchyAsync(filterUserId, parentId);
        sw.Stop();

        if (sw.ElapsedMilliseconds > 500)
        {
            Console.WriteLine($"[Performance Warning] Asset Hierarchy for Association {_tenantContext.AssociationId} (Parent: {parentId}) took {sw.ElapsedMilliseconds}ms for {hierarchy.Count()} assets.");
        }

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
    public IActionResult BulkCreate([FromBody] BulkCreateRequest request)
    {
        // Capture IDs from the current HTTP request context to pass them to the job
        int tenantId = _tenantContext.TenantId;
        int associationId = _tenantContext.AssociationId;
        int userId = _tenantContext.UserId;

        // Enqueue the heavy work to Hangfire
        _backgroundJobClient.Enqueue<IAssetService>(s => s.ProcessBulkCreateJobAsync(tenantId, associationId, userId, request));
        
        return Accepted(ApiResponse.SuccessResponse("Bulk asset creation started in background."));
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

    [HttpGet("{id}/tariffs")]
    public async Task<IActionResult> GetTariffs(int id)
    {
        var tariffs = await _assetService.GetAssignedTariffsAsync(id);
        return Ok(ApiResponse<IEnumerable<dynamic>>.SuccessResponse(tariffs));
    }
}
