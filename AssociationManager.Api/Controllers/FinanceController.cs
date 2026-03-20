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

[Authorize]
[Authorize(Policy = "RequireResident")]
[ApiController]
[Route("api/[controller]")]
public class FinanceController : ControllerBase
{
    private readonly IFinanceService _financeService;
    private readonly IAuditService _auditService;

    public FinanceController(IFinanceService financeService, IAuditService auditService)
    {
        _financeService = financeService;
        _auditService = auditService;
    }

    [HttpGet("invoices")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetInvoices([FromQuery] int? associationId = null)
    {
        var invoices = await _financeService.GetAllInvoicesAsync(associationId);
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
        await _auditService.LogAsync("Create Invoice", "Invoice", id);
        return CreatedAtAction(nameof(GetInvoice), new { id }, ApiResponse<int>.SuccessResponse(id, "Invoice created successfully."));
    }

    [HttpPut("invoices/{id}/status")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> UpdateInvoiceStatus(int id, [FromBody] string status)
    {
        var success = await _financeService.UpdateInvoiceStatusAsync(id, status);
        if (!success) return NotFound(ApiResponse.FailureResponse("Invoice not found for status update."));
        await _auditService.LogAsync("Update Invoice Status", "Invoice", id);
        return Ok(ApiResponse.SuccessResponse("Invoice status updated."));
    }

    [HttpGet("payments")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GetPayments()
    {
        var payments = await _financeService.GetPaymentsAsync();
        return Ok(ApiResponse<IEnumerable<Payment>>.SuccessResponse(payments));
    }

    [HttpPost("payments")]
    public async Task<IActionResult> CreatePayment([FromBody] Payment payment)
    {
        var id = await _financeService.CreatePaymentAsync(payment);
        await _auditService.LogAsync("Record Payment", "Payment", id);
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
