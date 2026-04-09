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
        IDashboardService dashboardService)
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
    }

    [HttpGet("admin/metrics")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetAdminMetrics()
    {
        var tenantId = _tenantContext.TenantId;
        var associationId = _tenantContext.AssociationId;

        var members = await _personRepository.GetAllAsync(tenantId, associationId);
        var invoices = await _invoiceRepository.GetAllAsync(tenantId, associationId);
        var payments = await _paymentRepository.GetByTenantIdAsync(tenantId, associationId);
        var workOrders = await _workOrderRepository.GetAllAsync(tenantId, associationId);
        var activity = await _auditLogRepository.GetByTenantIdAsync(tenantId, associationId);
        var finSummary = await _financeService.GetAssociationFinanceSummaryAsync(associationId, tenantId);

        var metrics = new AssociationDashboardMetrics
        {
            TotalMembers = members.Count(),
            TotalRevenueCollected = payments.Where(p => p.Status == "Paid" || p.Status == "Completed").Sum(p => p.Amount),
            TotalOutstanding = finSummary.TotalOutstanding,
            TotalAdvanceCredits = finSummary.TotalCredits,
            UnitsWithCredit = finSummary.UnitsWithCredit,
            PendingWorkOrders = workOrders.Count(w => w.Status != "Completed" && w.Status != "Closed"),
            RecentActivity = activity.OrderByDescending(a => a.Timestamp).Take(5).ToList()
        };

        return Ok(ApiResponse<AssociationDashboardMetrics>.SuccessResponse(metrics));
    }

    [HttpGet("admin/total-members")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetTotalMembers()
    {
        var count = await _dashboardService.GetTotalMembersAsync();
        return Ok(ApiResponse<int>.SuccessResponse(count));
    }

    [HttpGet("admin/committee-count")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetCommitteeCount()
    {
        var count = await _dashboardService.GetCommitteeCountAsync();
        return Ok(ApiResponse<int>.SuccessResponse(count));
    }

    [HttpGet("admin/revenue-30d")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetRevenue30D()
    {
        var revenue = await _dashboardService.GetRevenue30DAsync();
        return Ok(ApiResponse<decimal>.SuccessResponse(revenue));
    }

    [HttpGet("admin/outstanding")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetNetOutstanding()
    {
        var outstanding = await _dashboardService.GetNetOutstandingAsync();
        return Ok(ApiResponse<decimal>.SuccessResponse(outstanding));
    }

    [HttpGet("admin/advance-money")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> GetHeldAdvanceMoney()
    {
        var (amount, units) = await _dashboardService.GetHeldAdvanceMoneyAsync();
        return Ok(ApiResponse<object>.SuccessResponse(new { TotalAdvanceCredits = amount, UnitsWithCredit = units }));
    }

    [HttpGet("resident/metrics")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetResidentMetrics([FromQuery] int? assetId = null)
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
                // SCOPE: Only include assets in the current association
                var currentAssocOccupancies = occupancies
                    .Where(o => associationId == 0 || o.AssociationId == associationId)
                    .Select(o => o.AssetId);
                assetIds.AddRange(currentAssocOccupancies);
            }
        }

        if (!assetIds.Any()) 
        {
            return Ok(ApiResponse<ResidentDashboardMetrics>.SuccessResponse(new ResidentDashboardMetrics()));
        }

        var invoices = new List<Invoice>();
        var workOrders = new List<WorkOrder>();

        foreach (var aid in assetIds)
        {
            var assetInvoices = await _financeService.GetInvoicesByAssetIdAsync(aid, associationId);
            invoices.AddRange(assetInvoices);

            var assetWorkOrders = await _workOrderRepository.GetByAssetIdAsync(aid, tenantId, associationId);
            workOrders.AddRange(assetWorkOrders);
        }

        var finSummary = await _financeService.GetFinanceSummaryAsync(associationId, assetIds: assetIds);
        decimal totalCredit = finSummary.TotalAdvanceCredits;

        var unpaidInvoices = invoices.Where(i => i.Status != "Paid");
        // SMART SUM: Amount (Principal) + all Fine items + any virtual items
        var totalBalanceDue = unpaidInvoices.Sum(i => i.Amount + 
            i.LineItems.Where(l => l.InvoiceLineItemId == 0 || l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")).Sum(li => li.Amount));

        var metrics = new ResidentDashboardMetrics
        {
            BalanceDue = totalBalanceDue,
            WalletBalance = totalCredit,
            NetPosition = totalCredit - totalBalanceDue,
            PendingInvoices = unpaidInvoices.Count(),
            ActiveWorkOrders = workOrders.Count(w => w.Status != "Completed" && w.Status != "Closed")
        };

        return Ok(ApiResponse<ResidentDashboardMetrics>.SuccessResponse(metrics));
    }
}
