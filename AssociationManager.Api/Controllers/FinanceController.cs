using AssociationManager.Api.Authorization;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[RequireRole(AppRole.FinanceManager, AppRole.AssociationAdmin)]
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
    public async Task<IActionResult> GetInvoices()
    {
        var invoices = await _financeService.GetAllInvoicesAsync();
        return Ok(invoices);
    }

    [HttpGet("invoices/{id}")]
    public async Task<IActionResult> GetInvoice(int id)
    {
        var invoice = await _financeService.GetInvoiceByIdAsync(id);
        if (invoice == null) return NotFound();
        return Ok(invoice);
    }

    [HttpPost("invoices")]
    public async Task<IActionResult> CreateInvoice([FromBody] Invoice invoice)
    {
        var id = await _financeService.CreateInvoiceAsync(invoice);
        await _auditService.LogAsync("Create Invoice", "Invoice", id);
        return CreatedAtAction(nameof(GetInvoice), new { id }, invoice);
    }

    [HttpPut("invoices/{id}/status")]
    public async Task<IActionResult> UpdateInvoiceStatus(int id, [FromBody] string status)
    {
        var success = await _financeService.UpdateInvoiceStatusAsync(id, status);
        if (!success) return NotFound();
        await _auditService.LogAsync("Update Invoice Status", "Invoice", id);
        return NoContent();
    }

    [HttpGet("payments")]
    public async Task<IActionResult> GetPayments()
    {
        var payments = await _financeService.GetPaymentsAsync();
        return Ok(payments);
    }

    [HttpPost("payments")]
    public async Task<IActionResult> CreatePayment([FromBody] Payment payment)
    {
        var id = await _financeService.CreatePaymentAsync(payment);
        await _auditService.LogAsync("Record Payment", "Payment", id);
        return Ok(id);
    }
}
