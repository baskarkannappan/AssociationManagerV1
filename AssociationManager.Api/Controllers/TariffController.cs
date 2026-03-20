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

[Authorize(Policy = "RequireFinanceManager")]
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
    public async Task<IActionResult> GetGroups([FromQuery] int? associationId = null)
    {
        var groups = await _tariffService.GetTariffGroupsAsync(associationId);
        return Ok(ApiResponse<IEnumerable<TariffGroup>>.SuccessResponse(groups));
    }

    [HttpPost("groups")]
    public async Task<IActionResult> CreateGroup([FromBody] TariffGroup group)
    {
        var id = await _tariffService.CreateTariffGroupAsync(group);
        await _auditService.LogAsync("Create Tariff Group", "TariffGroup", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Tariff group created."));
    }

    [HttpDelete("groups/{id}")]
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
    public async Task<IActionResult> CreateLayer([FromBody] TariffLayer layer)
    {
        var id = await _tariffService.CreateTariffLayerAsync(layer);
        await _auditService.LogAsync("Create Tariff Layer", "TariffLayer", id);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Tariff layer created."));
    }

    [HttpDelete("layers/{id}")]
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

    [HttpDelete("assets/{assetId}/layers/{layerId}")]
    public async Task<IActionResult> RemoveTariff(int assetId, int layerId)
    {
        await _tariffService.RemoveTariffFromAssetAsync(assetId, layerId);
        await _auditService.LogAsync("Remove Tariff from Asset", "Asset", assetId);
        return Ok(ApiResponse.SuccessResponse("Tariff removed from asset."));
    }
}
