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
    private readonly ITenantContext _tenantContext;

    public DashboardController(
        IPersonRepository personRepository,
        IInvoiceRepository invoiceRepository,
        IPaymentRepository paymentRepository,
        IWorkOrderRepository workOrderRepository,
        IAuditLogRepository auditLogRepository,
        IFinanceService financeService,
        ITenantContext tenantContext)
    {
        _personRepository = personRepository;
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _workOrderRepository = workOrderRepository;
        _auditLogRepository = auditLogRepository;
        _financeService = financeService;
        _tenantContext = tenantContext;
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
            TotalRevenueCollected = payments.Where(p => p.CreatedDate > DateTime.UtcNow.AddDays(-30)).Sum(p => p.Amount),
            TotalOutstanding = finSummary.TotalOutstanding,
            TotalAdvanceCredits = finSummary.TotalCredits,
            UnitsWithCredit = finSummary.UnitsWithCredit,
            PendingWorkOrders = workOrders.Count(w => w.Status != "Completed" && w.Status != "Closed"),
            RecentActivity = activity.OrderByDescending(a => a.Timestamp).Take(5).ToList()
        };

        return Ok(ApiResponse<AssociationDashboardMetrics>.SuccessResponse(metrics));
    }

    [HttpGet("resident/metrics")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetResidentMetrics([FromQuery] int assetId)
    {
        var tenantId = _tenantContext.TenantId;
        var associationId = _tenantContext.AssociationId;

        var invoices = await _invoiceRepository.GetByAssetIdAsync(assetId, tenantId, associationId);
        var workOrders = await _workOrderRepository.GetByAssetIdAsync(assetId, tenantId, associationId);

        var metrics = new ResidentDashboardMetrics
        {
            BalanceDue = invoices.Where(i => i.Status != "Paid").Sum(i => i.Amount),
            PendingInvoices = invoices.Count(i => i.Status != "Paid"),
            ActiveWorkOrders = workOrders.Count(w => w.Status != "Completed" && w.Status != "Closed")
        };

        return Ok(ApiResponse<ResidentDashboardMetrics>.SuccessResponse(metrics));
    }
}
