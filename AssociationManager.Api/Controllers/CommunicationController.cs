using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Hangfire;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[Authorize(Policy = "RequireAssociationAdmin")]
[ApiController]
[Route("api/[controller]")]
public class CommunicationController : ControllerBase
{
    private readonly ICommunicationRepository _communicationRepository;
    private readonly ITenantContext _tenantContext;
    private readonly IRecurringJobManager _recurringJobManager;

    public CommunicationController(ICommunicationRepository communicationRepository, ITenantContext tenantContext, IRecurringJobManager recurringJobManager)
    {
        _communicationRepository = communicationRepository;
        _tenantContext = tenantContext;
        _recurringJobManager = recurringJobManager;
    }

    [HttpGet("logs")]
    public async Task<IActionResult> GetLogs([FromQuery] int? status = null)
    {
        var logs = await _communicationRepository.GetByAssociationIdAsync(_tenantContext.TenantId, _tenantContext.AssociationId, status);
        return Ok(ApiResponse<IEnumerable<CommunicationLog>>.SuccessResponse(logs));
    }

    [HttpPost("logs/{id}/cancel")]
    public async Task<IActionResult> CancelEmail(int id)
    {
        var log = await _communicationRepository.GetByIdAsync(id, _tenantContext.TenantId, _tenantContext.AssociationId);
        if (log == null) return NotFound(ApiResponse.FailureResponse("Email log not found."));
        
        if (log.Status != CommunicationStatus.Posted && log.Status != CommunicationStatus.Resend)
        {
            return BadRequest(ApiResponse.FailureResponse("Only pending or resend-status emails can be cancelled."));
        }

        var success = await _communicationRepository.UpdateStatusAsync(id, _tenantContext.TenantId, (int)CommunicationStatus.Archive);
        return success ? Ok(ApiResponse.SuccessResponse("Email cancelled and archived.")) : BadRequest(ApiResponse.FailureResponse("Failed to cancel email."));
    }

    [HttpPost("logs/{id}/resend")]
    public async Task<IActionResult> ResendEmail(int id)
    {
        var log = await _communicationRepository.GetByIdAsync(id, _tenantContext.TenantId, _tenantContext.AssociationId);
        if (log == null) return NotFound(ApiResponse.FailureResponse("Email log not found."));

        var success = await _communicationRepository.UpdateStatusAsync(id, _tenantContext.TenantId, (int)CommunicationStatus.Resend);
        return success ? Ok(ApiResponse.SuccessResponse("Email marked for resending.")) : BadRequest(ApiResponse.FailureResponse("Failed to update status."));
    }

    [HttpPost("logs/process")]
    public IActionResult ProcessQueue()
    {
        _recurringJobManager.Trigger("automated-email-dispatch");
        return Ok(ApiResponse.SuccessResponse("Background process triggered. Emails will be processed shortly."));
    }
}
