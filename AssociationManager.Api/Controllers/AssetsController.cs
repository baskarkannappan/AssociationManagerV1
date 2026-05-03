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
using Microsoft.AspNetCore.SignalR;
using AssociationManager.Realtime.Hubs;

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
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly ILogger<AssetsController> _logger;

    public AssetsController(
        IAssetService assetService, 
        IAuditService auditService, 
        AssociationManager.Shared.Interfaces.ITenantContext tenantContext, 
        IRuleEngineService ruleEngine,
        IBackgroundJobClient backgroundJobClient,
        IHubContext<NotificationHub> hubContext,
        ILogger<AssetsController> logger)
    {
        _assetService = assetService;
        _auditService = auditService;
        _tenantContext = tenantContext;
        _ruleEngine = ruleEngine;
        _backgroundJobClient = backgroundJobClient;
        _hubContext = hubContext;
        _logger = logger;
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
        
        _logger.LogInformation("[Assets] Hierarchy request - User: {UserId}, RoleLevel: {UserLevel}, Association: {AssociationId}, ResidentOnly: {IsResidentOnly}, FilterUser: {FilterUser}", 
            _tenantContext.UserId, securityContext.UserLevel, securityContext.AssociationId, isResidentOnly, filterUserId);

        var hierarchy = await _assetService.GetHierarchyAsync(filterUserId, parentId);
        sw.Stop();

        _logger.LogInformation("[Assets] Hierarchy returned {Count} assets in {Elapsed}ms", hierarchy.Count(), sw.ElapsedMilliseconds);

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
        
        await _hubContext.Clients.Group($"Association_{_tenantContext.AssociationId}")
            .SendAsync("HierarchyChanged");
            
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

        await _hubContext.Clients.Group($"Association_{_tenantContext.AssociationId}")
            .SendAsync("HierarchyChanged");

        return Ok(ApiResponse.SuccessResponse("Asset updated successfully."));
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "RequireAssetManager")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _assetService.DeleteAsync(id);
        if (!success) return NotFound(ApiResponse.FailureResponse("Asset not found for deletion."));
        await _auditService.LogAsync("Delete Asset", "Asset", id);

        await _hubContext.Clients.Group($"Association_{_tenantContext.AssociationId}")
            .SendAsync("HierarchyChanged");

        return Ok(ApiResponse.SuccessResponse("Asset deleted successfully."));
    }

    [HttpGet("{id}/tariffs")]
    public async Task<IActionResult> GetTariffs(int id)
    {
        var tariffs = await _assetService.GetAssignedTariffsAsync(id);
        return Ok(ApiResponse<IEnumerable<dynamic>>.SuccessResponse(tariffs));
    }
}
