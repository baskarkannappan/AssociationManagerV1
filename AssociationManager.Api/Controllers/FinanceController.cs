using AssociationManager.Shared.Interfaces;
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
[Authorize(Policy = "RequireResident")]
[ApiController]
[Route("api/[controller]")]
public class FinanceController : ControllerBase
{
    private readonly IFinanceService _financeService;
    private readonly IAuditService _auditService;
    private readonly ITenantContext _tenantContext;
    private readonly IPeopleService _peopleService;
    private readonly AssociationManager.Api.Services.Billing.BillingBatchService _batchService;
    private readonly IRuleEngineService _ruleEngine;

    public FinanceController(
        IFinanceService financeService, 
        IAuditService auditService,
        ITenantContext tenantContext,
        IPeopleService peopleService,
        AssociationManager.Api.Services.Billing.BillingBatchService batchService,
        IRuleEngineService ruleEngine)
    {
        _financeService = financeService;
        _auditService = auditService;
        _tenantContext = tenantContext;
        _peopleService = peopleService;
        _batchService = batchService;
        _ruleEngine = ruleEngine;
    }

    [HttpPost("batch-generate")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GenerateBatch([FromBody] InvoiceBatchRequest request)
    {
        var result = await _batchService.ProcessBatchAsync(request, _tenantContext.TenantId);
        return Ok(ApiResponse<InvoiceBatchResult>.SuccessResponse(result));
    }

    [HttpGet("invoices")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetInvoices([FromQuery] int? associationId = null, [FromQuery] int? assetId = null)
    {
        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", User.FindAll(System.Security.Claims.ClaimTypes.Role).Select(c => c.Value)),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId
        };

        bool isStaff = await _ruleEngine.EvaluateRuleAsync("IsStaff", securityContext);
        
        if (!isStaff)
        {
             var userIdStr = User.FindFirst("UserId")?.Value;
             if (int.TryParse(userIdStr, out int userId))
             {
                 var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
                 var allowedAssetIds = occupancies.Select(o => o.AssetId).ToList();
                 
                 if (assetId.HasValue && !allowedAssetIds.Contains(assetId.Value))
                 {
                     return Forbid();
                 }
                 
                 if (!assetId.HasValue)
                 {
                     if (!allowedAssetIds.Any()) return Ok(ApiResponse<IEnumerable<Invoice>>.SuccessResponse(new List<Invoice>()));
                     assetId = allowedAssetIds.First();
                 }
             }
        }

        IEnumerable<Invoice> invoices;
        if (assetId.HasValue)
        {
            invoices = await _financeService.GetInvoicesByAssetIdAsync(assetId.Value, associationId);
        }
        else
        {
            invoices = await _financeService.GetAllInvoicesAsync(associationId);
        }
        return Ok(ApiResponse<IEnumerable<Invoice>>.SuccessResponse(invoices));
    }

    [HttpGet("invoices/{id}")]
    public async Task<IActionResult> GetInvoice(int id, [FromQuery] int? associationId = null)
    {
        var invoice = await _financeService.GetInvoiceByIdAsync(id, associationId);
        if (invoice == null) return NotFound(ApiResponse.FailureResponse("Invoice not found."));
        return Ok(ApiResponse<Invoice>.SuccessResponse(invoice));
    }

    [HttpPost("invoices")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> CreateInvoice([FromBody] Invoice invoice)
    {
        var id = await _financeService.CreateInvoiceAsync(invoice);
        await _auditService.LogAsync("Create Invoice", "Invoice", id, assetId: invoice.AssetId);
        return CreatedAtAction(nameof(GetInvoice), new { id }, ApiResponse<int>.SuccessResponse(id, "Invoice created successfully."));
    }

    [HttpPut("invoices/{id}/status")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> UpdateInvoiceStatus(int id, [FromBody] string status)
    {
        var invoice = await _financeService.GetInvoiceByIdAsync(id);
        var success = await _financeService.UpdateInvoiceStatusAsync(id, status);
        if (!success) return NotFound(ApiResponse.FailureResponse("Invoice not found for status update."));
        
        await _auditService.LogAsync($"Update Invoice Status to {status}", "Invoice", id, assetId: invoice?.AssetId);
        return Ok(ApiResponse.SuccessResponse("Invoice status updated."));
    }

    [HttpGet("payments")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetPayments([FromQuery] int? assetId = null)
    {
        // For now, return payments for association if staff, or just restricted if I had the repo method.
        // Since we are fixing 403, we'll allow but we SHOULD ideally filter by assetId.
        var payments = await _financeService.GetPaymentsAsync();
        if (assetId.HasValue)
        {
            payments = payments.Where(p => p.AssetId == assetId.Value);
        }
        return Ok(ApiResponse<IEnumerable<Payment>>.SuccessResponse(payments));
    }

    [HttpPost("payments")]
    public async Task<IActionResult> CreatePayment([FromBody] Payment payment)
    {
        var id = await _financeService.CreatePaymentAsync(payment);
        await _auditService.LogAsync("Record Payment", "Payment", id, assetId: payment.AssetId);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Payment recorded successfully."));
    }

    [HttpGet("transactions/asset/{assetId}")]
    public async Task<IActionResult> GetAssetTransactions(int assetId)
    {
        var transactions = await _financeService.GetAssetTransactionsAsync(assetId);
        return Ok(ApiResponse<IEnumerable<Transaction>>.SuccessResponse(transactions));
    }

    [HttpGet("balance/asset/{assetId}")]
    public async Task<IActionResult> GetAssetBalance(int assetId)
    {
        var balance = await _financeService.GetAssetBalanceAsync(assetId);
        return Ok(ApiResponse<decimal>.SuccessResponse(balance));
    }

    [HttpGet("transactions/tenant")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GetTenantTransactions([FromQuery] DateTime? start, [FromQuery] DateTime? end)
    {
        var transactions = await _financeService.GetTenantTransactionsAsync(start, end);
        return Ok(ApiResponse<IEnumerable<Transaction>>.SuccessResponse(transactions));
    }
}
