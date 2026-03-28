using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class TariffController : ControllerBase
{
    private readonly ITariffService _tariffService;
    private readonly IAuditService _auditService;

    public TariffController(ITariffService tariffService, IAuditService auditService)
    {
        _tariffService = tariffService;
        _auditService = auditService;
    }

    [HttpGet("groups")]
    [AllowAnonymous] // Or refined to resident if needed, but usually group list is safer. 
    // Wait, the user is getting 403 as Asset Manager. 
    // Asset Manager is level 60. Finance Manager is 40. 
    // If I put RequireFinanceManager at class level, it's fine.
    public async Task<IActionResult> GetGroups([FromQuery] int? associationId = null)
    {
        var groups = await _tariffService.GetTariffGroupsAsync(associationId);
        return Ok(ApiResponse<IEnumerable<TariffGroup>>.SuccessResponse(groups));
    }

    [HttpPost("groups")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> CreateGroup([FromBody] TariffGroup group)
    {
        var id = await _tariffService.CreateTariffGroupAsync(group);
        await _auditService.LogAsync("Create Tariff Group", "TariffGroup", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Tariff group created."));
    }

    [HttpDelete("groups/{id}")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> DeleteGroup(int id)
    {
        await _tariffService.DeleteTariffGroupAsync(id);
        await _auditService.LogAsync("Delete Tariff Group", "TariffGroup", id);
        return Ok(ApiResponse.SuccessResponse("Tariff group deleted."));
    }

    [HttpGet("groups/{groupId}/layers")]
    public async Task<IActionResult> GetLayers(int groupId)
    {
        var layers = await _tariffService.GetTariffLayersAsync(groupId);
        return Ok(ApiResponse<IEnumerable<TariffLayer>>.SuccessResponse(layers));
    }

    [HttpPost("layers")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> CreateLayer([FromBody] TariffLayer layer)
    {
        var id = await _tariffService.CreateTariffLayerAsync(layer);
        await _auditService.LogAsync("Create Tariff Layer", "TariffLayer", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Tariff layer created."));
    }

    [HttpDelete("layers/{id}")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> DeleteLayer(int id)
    {
        await _tariffService.DeleteTariffLayerAsync(id);
        await _auditService.LogAsync("Delete Tariff Layer", "TariffLayer", id);
        return Ok(ApiResponse.SuccessResponse("Tariff layer deleted."));
    }

    [HttpGet("assets/{assetId}")]
    public async Task<IActionResult> GetAssetTariffs(int assetId)
    {
        var tariffs = await _tariffService.GetAssetTariffsAsync(assetId);
        return Ok(ApiResponse<IEnumerable<AssetTariff>>.SuccessResponse(tariffs));
    }

    [HttpPost("assets/assign")]
    public async Task<IActionResult> AssignTariff([FromBody] AssetTariff tariff)
    {
        await _tariffService.AssignTariffToAssetAsync(tariff);
        await _auditService.LogAsync("Assign Tariff to Asset", "Asset", tariff.AssetId);
        return Ok(ApiResponse.SuccessResponse("Tariff assigned to asset."));
    }

    [HttpPost("assets/bulk-assign")]
    public async Task<IActionResult> BulkAssignTariffs([FromBody] List<AssetTariff> tariffs)
    {
        if (tariffs == null || !tariffs.Any()) return BadRequest(ApiResponse.FailureResponse("No assignments provided."));
        
        foreach (var t in tariffs)
        {
            await _tariffService.AssignTariffToAssetAsync(t);
        }
        
        await _auditService.LogAsync("Bulk Assign Tariffs", "Asset", tariffs.First().AssetId);
        return Ok(ApiResponse.SuccessResponse($"Assigned tariffs to {tariffs.Count} assets."));
    }

    [HttpDelete("assets/{assetId}/layers/{layerId}")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> RemoveTariff(int assetId, int layerId)
    {
        await _tariffService.RemoveTariffFromAssetAsync(assetId, layerId);
        await _auditService.LogAsync("Remove Tariff from Asset", "Asset", assetId);
        return Ok(ApiResponse.SuccessResponse("Tariff removed from asset."));
    }
}
