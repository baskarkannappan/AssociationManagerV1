using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CommunicationsController : ControllerBase
{
    private readonly ICommunicationsService _communicationsService;
    private readonly IAuditService _auditService;

    public CommunicationsController(ICommunicationsService communicationsService, IAuditService auditService)
    {
        _communicationsService = communicationsService;
        _auditService = auditService;
    }

    [HttpGet("broadcasts")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetBroadcasts([FromQuery] int? assetId = null, [FromQuery] int? associationId = null)
    {
        IEnumerable<Broadcast> broadcasts;
        if (assetId.HasValue)
        {
            broadcasts = await _communicationsService.GetBroadcastsByAssetAsync(assetId.Value);
        }
        else
        {
            broadcasts = await _communicationsService.GetAllBroadcastsAsync(associationId);
        }
        return Ok(ApiResponse<IEnumerable<Broadcast>>.SuccessResponse(broadcasts));
    }

    [HttpGet("broadcasts/{id}")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetBroadcast(int id)
    {
        var broadcast = await _communicationsService.GetBroadcastByIdAsync(id);
        if (broadcast == null) return NotFound(ApiResponse.FailureResponse("Broadcast not found."));
        return Ok(ApiResponse<Broadcast>.SuccessResponse(broadcast));
    }

    [HttpPost("broadcasts")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> CreateBroadcast([FromBody] Broadcast broadcast)
    {
        var id = await _communicationsService.CreateBroadcastAsync(broadcast);
        await _auditService.LogAsync("Create Broadcast", "Broadcast", id);
        return CreatedAtAction(nameof(GetBroadcast), new { id }, ApiResponse<int>.SuccessResponse(id, "Broadcast created."));
    }

    [HttpDelete("broadcasts/{id}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _communicationsService.DeleteBroadcastAsync(id);
        if (!success) return NotFound(ApiResponse.FailureResponse("Broadcast not found for deletion."));
        await _auditService.LogAsync("Delete Broadcast", "Broadcast", id);
        return Ok(ApiResponse.SuccessResponse("Broadcast deleted."));
    }
}
