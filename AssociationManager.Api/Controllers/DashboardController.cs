using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class DashboardController : ControllerBase
{
    private readonly IPersonRepository _personRepository;
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly IWorkOrderRepository _workOrderRepository;
    private readonly IAuditLogRepository _auditLogRepository;
    private readonly IFinanceService _financeService;
    private readonly IPeopleService _peopleService;
    private readonly ITenantContext _tenantContext;
    private readonly ITransactionRepository _transactionRepository;
    private readonly IDashboardService _dashboardService;
    private readonly IDashboardRepository _dashboardRepository;
    private readonly IGovernanceService _governanceService;
    private readonly IAssetService _assetService;

    public DashboardController(
        IPersonRepository personRepository,
        IInvoiceRepository invoiceRepository,
        IPaymentRepository paymentRepository,
        IWorkOrderRepository workOrderRepository,
        IAuditLogRepository auditLogRepository,
        IFinanceService financeService,
        IPeopleService peopleService,
        ITenantContext tenantContext,
        ITransactionRepository transactionRepository,
        IDashboardService dashboardService,
        IDashboardRepository dashboardRepository,
        IGovernanceService governanceService,
        IAssetService assetService)
    {
        _personRepository = personRepository;
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _workOrderRepository = workOrderRepository;
        _auditLogRepository = auditLogRepository;
        _financeService = financeService;
        _peopleService = peopleService;
        _tenantContext = tenantContext;
        _transactionRepository = transactionRepository;
        _dashboardService = dashboardService;
        _dashboardRepository = dashboardRepository;
        _governanceService = governanceService;
        _assetService = assetService;
    }

    [HttpGet("admin/metrics")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetAdminMetrics([FromQuery] int? associationId = null)
    {
        var tenantId = _tenantContext.TenantId;
        var aid = associationId ?? _tenantContext.AssociationId;

        var membersTask = _personRepository.GetAllAsync(tenantId, aid);
        var invoicesTask = _invoiceRepository.GetAllAsync(tenantId, aid);
        var paymentsTask = _paymentRepository.GetByTenantIdAsync(tenantId, aid);
        var workOrdersTask = _workOrderRepository.GetAllAsync(tenantId, aid);
        var activityTask = _auditLogRepository.GetByTenantIdAsync(tenantId, aid);
        var finSummaryTask = _financeService.GetAssociationFinanceSummaryAsync(aid, tenantId);

        await Task.WhenAll(membersTask, invoicesTask, paymentsTask, workOrdersTask, activityTask, finSummaryTask);

        var metrics = new AssociationDashboardMetrics
        {
            TotalMembers = (await membersTask).Count(),
            TotalRevenueCollected = (await paymentsTask).Where(p => p.Status == "Paid" || p.Status == "Completed").Sum(p => p.Amount),
            TotalOutstanding = (await finSummaryTask).TotalOutstanding,
            TotalAdvanceCredits = (await finSummaryTask).TotalCredits,
            UnitsWithCredit = (await finSummaryTask).UnitsWithCredit,
            PendingWorkOrders = (await workOrdersTask).Count(w => w.Status != "Completed" && w.Status != "Closed"),
            RecentActivity = (await activityTask).OrderByDescending(a => a.Timestamp).Take(5).ToList()
        };

        return Ok(ApiResponse<AssociationDashboardMetrics>.SuccessResponse(metrics));
    }

    [HttpGet("admin/total-members")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetTotalMembers([FromQuery] int? associationId = null)
    {
        var aid = associationId ?? _tenantContext.AssociationId;
        var count = await _dashboardRepository.GetTotalMembersAsync(_tenantContext.TenantId, aid);
        return Ok(ApiResponse<int>.SuccessResponse(count));
    }

    [HttpGet("admin/committee-count")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetCommitteeCount([FromQuery] int? associationId = null)
    {
        var aid = associationId ?? _tenantContext.AssociationId;
        var count = await _dashboardRepository.GetCommitteeCountAsync(_tenantContext.TenantId, aid);
        return Ok(ApiResponse<int>.SuccessResponse(count));
    }

    [HttpGet("admin/revenue-30d")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetRevenue30D([FromQuery] int? associationId = null)
    {
        var aid = associationId ?? _tenantContext.AssociationId;
        var revenue = await _dashboardRepository.GetRevenue30DAsync(_tenantContext.TenantId, aid);
        return Ok(ApiResponse<decimal>.SuccessResponse(revenue));
    }

    [HttpGet("admin/outstanding")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetNetOutstanding([FromQuery] int? associationId = null)
    {
        var aid = associationId ?? _tenantContext.AssociationId;
        var summary = await _financeService.GetFinanceSummaryAsync(aid);
        return Ok(ApiResponse<decimal>.SuccessResponse(summary.TotalUnpaid));
    }

    [HttpGet("admin/advance-money")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetHeldAdvanceMoney([FromQuery] int? associationId = null)
    {
        var aid = associationId ?? _tenantContext.AssociationId;
        (decimal amount, int units) = await _dashboardRepository.GetHeldAdvanceMoneyAsync(_tenantContext.TenantId, aid);
        return Ok(ApiResponse<object>.SuccessResponse(new { TotalAdvanceCredits = amount, UnitsWithCredit = units }));
    }

    [HttpGet("admin/overview")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetAdminOverview([FromQuery] int? associationId = null)
    {
        var tenantId = _tenantContext.TenantId;
        var aid = associationId ?? _tenantContext.AssociationId;

        // Parallel fetch all dashboard components
        var metricsTask = GetAdminMetricsDataAsync(aid);
        var membersCountTask = _dashboardRepository.GetTotalMembersAsync(tenantId, aid);
        var committeeCountTask = _dashboardRepository.GetCommitteeCountAsync(tenantId, aid);
        var revenue30DTask = _dashboardRepository.GetRevenue30DAsync(tenantId, aid);
        var outstandingTask = _financeService.GetFinanceSummaryAsync(aid);
        var advanceMoneyTask = _dashboardRepository.GetHeldAdvanceMoneyAsync(tenantId, aid);
        var profileTask = _governanceService.GetProfileAsync(aid);
        var committeeListTask = _governanceService.GetCommitteeMembersAsync(aid, true);
        var meetingsTask = _governanceService.GetMeetingsAsync(aid);

        await Task.WhenAll(
            metricsTask, membersCountTask, committeeCountTask, 
            revenue30DTask, outstandingTask, advanceMoneyTask,
            profileTask, committeeListTask, meetingsTask);

        var overview = new AdminDashboardOverview
        {
            Metrics = await metricsTask,
            TotalMembers = await membersCountTask,
            CommitteeCount = await committeeCountTask,
            Revenue30D = await revenue30DTask,
            NetOutstanding = (await outstandingTask).TotalUnpaid,
            HeldAdvanceMoney = (await advanceMoneyTask).amount,
            UnitsWithCredit = (await advanceMoneyTask).units,
            Profile = await profileTask,
            Committee = (await committeeListTask).ToList(),
            UpcomingMeetings = (await meetingsTask).ToList()
        };

        return Ok(ApiResponse<AdminDashboardOverview>.SuccessResponse(overview));
    }

    private async Task<AssociationDashboardMetrics> GetAdminMetricsDataAsync(int associationId)
    {
        var tenantId = _tenantContext.TenantId;
        var membersTask = _personRepository.GetAllAsync(tenantId, associationId);
        var invoicesTask = _invoiceRepository.GetAllAsync(tenantId, associationId);
        var paymentsTask = _paymentRepository.GetByTenantIdAsync(tenantId, associationId);
        var workOrdersTask = _workOrderRepository.GetAllAsync(tenantId, associationId);
        var activityTask = _auditLogRepository.GetByTenantIdAsync(tenantId, associationId);
        var finSummaryTask = _financeService.GetAssociationFinanceSummaryAsync(associationId, tenantId);

        await Task.WhenAll(membersTask, invoicesTask, paymentsTask, workOrdersTask, activityTask, finSummaryTask);

        return new AssociationDashboardMetrics
        {
            TotalMembers = (await membersTask).Count(),
            TotalRevenueCollected = (await paymentsTask).Where(p => p.Status == "Paid" || p.Status == "Completed").Sum(p => p.Amount),
            TotalOutstanding = (await finSummaryTask).TotalOutstanding,
            TotalAdvanceCredits = (await finSummaryTask).TotalCredits,
            UnitsWithCredit = (await finSummaryTask).UnitsWithCredit,
            PendingWorkOrders = (await workOrdersTask).Count(w => w.Status != "Completed" && w.Status != "Closed"),
            RecentActivity = (await activityTask).OrderByDescending(a => a.Timestamp).Take(5).ToList()
        };
    }

    [HttpGet("resident/metrics")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetResidentMetrics([FromQuery] int? assetId = null)
    {
        var metrics = await CalculateResidentMetricsAsync(assetId);
        return Ok(ApiResponse<ResidentDashboardMetrics>.SuccessResponse(metrics));
    }

    [HttpGet("resident/overview")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetResidentOverview()
    {
        var tenantId = _tenantContext.TenantId;
        var associationId = _tenantContext.AssociationId;
        var userIdStr = User.FindFirst("UserId")?.Value;

        if (!int.TryParse(userIdStr, out int userId))
            return Unauthorized();

        // 1. Fetch Occupancies First (Base dependency)
        var occupancies = (await _peopleService.GetOccupancyByUserIdAsync(userId))
            .Where(o => associationId == 0 || o.AssociationId == associationId)
            .ToList();

        var overview = new ResidentDashboardOverview { Occupancies = occupancies };
        if (!occupancies.Any())
            return Ok(ApiResponse<ResidentDashboardOverview>.SuccessResponse(overview));

        // 2. Parallelize everything else
        var assetIds = occupancies.Select(o => o.AssetId).ToList();
        
        var metricsTask = CalculateResidentMetricsAsync();
        var invoicesTask = _financeService.GetInvoicesByAssetIdAsync(assetIds.First(), associationId); // Simplified for MVP: primary asset invoices
        var balanceTask = _financeService.GetFinanceSummaryAsync(associationId, assetIds: assetIds);
        var profileTask = _governanceService.GetProfileAsync(associationId);
        Task<Asset>? unitTask = null;
        if (occupancies.Count == 1)
        {
            unitTask = _assetService.GetByIdAsync(occupancies[0].AssetId);
        }

        await Task.WhenAll(metricsTask, invoicesTask, balanceTask, profileTask);
        if (unitTask != null) await unitTask;

        overview.Metrics = await metricsTask;
        overview.RecentInvoices = (await invoicesTask).Where(i => i.Status != "Draft").Take(50).ToList();
        overview.MyBalance = (await balanceTask).TotalAdvanceCredits; // Summing total advance money
        overview.Profile = await profileTask;
        if (unitTask != null) overview.MyUnit = await unitTask;

        return Ok(ApiResponse<ResidentDashboardOverview>.SuccessResponse(overview));
    }

    private async Task<ResidentDashboardMetrics> CalculateResidentMetricsAsync(int? assetId = null)
    {
        var tenantId = _tenantContext.TenantId;
        var associationId = _tenantContext.AssociationId;
        var assetIds = new List<int>();

        if (assetId.HasValue)
        {
            assetIds.Add(assetId.Value);
        }
        else
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr, out int userId))
            {
                var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
                var currentAssocOccupancies = occupancies
                    .Where(o => associationId == 0 || o.AssociationId == associationId)
                    .Select(o => o.AssetId);
                assetIds.AddRange(currentAssocOccupancies);
            }
        }

        if (!assetIds.Any()) return new ResidentDashboardMetrics();

        var invoices = new List<Invoice>();
        var workOrders = new List<WorkOrder>();

        foreach (var aid in assetIds)
        {
            var assetInvoices = (await _financeService.GetInvoicesByAssetIdAsync(aid, associationId)).Where(i => i.Status != "Draft");
            invoices.AddRange(assetInvoices);

            var assetWorkOrders = await _workOrderRepository.GetByAssetIdAsync(aid, tenantId, associationId);
            workOrders.AddRange(assetWorkOrders);
        }

        var finSummary = await _financeService.GetFinanceSummaryAsync(associationId, assetIds: assetIds);
        decimal totalCredit = finSummary.TotalAdvanceCredits;

        var unpaidInvoices = invoices.Where(i => i.Status != "Paid" && i.Status != "Draft" && i.Status != "Cancelled" && i.Status != "Void");
        var totalBalanceDue = unpaidInvoices.Sum(i => i.Amount + 
            i.LineItems.Where(l => l.InvoiceLineItemId == 0 || l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")).Sum(li => li.Amount));

        return new ResidentDashboardMetrics
        {
            BalanceDue = totalBalanceDue,
            CreditAvailable = totalCredit,
            NetPosition = totalCredit - totalBalanceDue,
            PendingInvoices = unpaidInvoices.Count(),
            ActiveWorkOrders = workOrders.Count(w => w.Status != "Completed" && w.Status != "Closed")
        };
    }
}
