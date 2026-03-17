using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
    public async Task<IActionResult> GetBroadcasts()
    {
        var broadcasts = await _communicationsService.GetAllBroadcastsAsync();
        return Ok(broadcasts);
    }

    [HttpGet("broadcasts/{id}")]
    public async Task<IActionResult> GetBroadcast(int id)
    {
        var broadcast = await _communicationsService.GetBroadcastByIdAsync(id);
        if (broadcast == null) return NotFound();
        return Ok(broadcast);
    }

    [HttpPost("broadcasts")]
    public async Task<IActionResult> CreateBroadcast([FromBody] Broadcast broadcast)
    {
        var id = await _communicationsService.CreateBroadcastAsync(broadcast);
        await _auditService.LogAsync("Create Broadcast", "Broadcast", id);
        return CreatedAtAction(nameof(GetBroadcast), new { id }, broadcast);
    }

    [HttpDelete("broadcasts/{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var success = await _communicationsService.DeleteBroadcastAsync(id);
        if (!success) return NotFound();
        await _auditService.LogAsync("Delete Broadcast", "Broadcast", id);
        return NoContent();
    }
}
