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
    private readonly IPlatformBillingRepository _platformBillingRepository;

    public DashboardController(
        IAssociationRepository associationRepository,
        IUserRepository userRepository,
        IAuditLogRepository auditLogRepository,
        IPlatformBillingRepository platformBillingRepository)
    {
        _associationRepository = associationRepository;
        _userRepository = userRepository;
        _auditLogRepository = auditLogRepository;
        _platformBillingRepository = platformBillingRepository;
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

            // Calculate Revenue MTD
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);
            metrics.RevenueMTD = await _platformBillingRepository.GetRevenueAsync(startOfMonth, now);

            // Calculate Growth (vs Last Month)
            var startOfLastMonth = startOfMonth.AddMonths(-1);
            var endOfLastMonth = startOfMonth.AddDays(-1);
            var lastMonthRevenue = await _platformBillingRepository.GetRevenueAsync(startOfLastMonth, endOfLastMonth);
            
            if (lastMonthRevenue > 0)
            {
                metrics.MTDGrowth = ((metrics.RevenueMTD - lastMonthRevenue) / lastMonthRevenue) * 100;
            }
            else if (metrics.RevenueMTD > 0)
            {
                metrics.MTDGrowth = 100; // 100% growth if we had nothing last month
            }

            return Ok(ApiResponse<CorporateDashboardMetrics>.SuccessResponse(metrics));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse("Failed to load dashboard metrics: " + ex.Message));
        }
    }
}
