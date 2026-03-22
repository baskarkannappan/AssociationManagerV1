using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "RequireCorporate")]
public class DashboardController : ControllerBase
{
    private readonly IAssociationRepository _associationRepository;
    private readonly IUserRepository _userRepository;
    private readonly IAuditLogRepository _auditLogRepository;

    public DashboardController(
        IAssociationRepository associationRepository,
        IUserRepository userRepository,
        IAuditLogRepository auditLogRepository)
    {
        _associationRepository = associationRepository;
        _userRepository = userRepository;
        _auditLogRepository = auditLogRepository;
    }

    [HttpGet("metrics")]
    public async Task<IActionResult> GetMetrics()
    {
        try
        {
            var associations = await _associationRepository.GetAllAsync();
            var users = await _userRepository.GetAllAsync();
            
            // Note: In an ideal scenario, the database repository should have a GetRecentAsync(count) procedure. 
            // For now, pulling all from tenant 1 and truncating in memory to ensure we have data.
            var logs = await _auditLogRepository.GetByTenantIdAsync(1, 0); 
            var topLogs = logs?.OrderByDescending(l => l.Timestamp).Take(10) ?? Array.Empty<AuditLog>();

            var metrics = new CorporateDashboardMetrics
            {
                TotalAssociations = associations?.Count() ?? 0,
                TotalUsers = users?.Count() ?? 0,
                RecentActivities = topLogs
            };

            return Ok(ApiResponse<CorporateDashboardMetrics>.SuccessResponse(metrics));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse("Failed to load dashboard metrics: " + ex.Message));
        }
    }
}
