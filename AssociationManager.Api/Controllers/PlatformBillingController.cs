using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class PlatformBillingController : ControllerBase
{
    private readonly IPlatformBillingService _billingService;
    private readonly ITenantContext _tenantContext;

    public PlatformBillingController(IPlatformBillingService billingService, ITenantContext tenantContext)
    {
        _billingService = billingService;
        _tenantContext = tenantContext;
    }

    [HttpGet("my-invoices")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> GetMyInvoices()
    {
        var associationId = _tenantContext.AssociationId;
        
        // If PlatformAdmin at Association UI, they might have AssociationId 0.
        // In this case, we search for the association they are trying to view or just show all for test.
        if (associationId == 0 && (_tenantContext.IsPlatformAdmin || _tenantContext.IsSystemAdmin))
        {
            var all = await _billingService.GetAllInvoicesAsync();
             return Ok(ApiResponse<IEnumerable<PlatformInvoice>>.SuccessResponse(all));
        }

        var invoices = await _billingService.GetInvoicesForAssociationAsync(associationId);
        return Ok(ApiResponse<IEnumerable<PlatformInvoice>>.SuccessResponse(invoices));
    }
    
    [HttpGet("billing-account")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> GetBillingAccount()
    {
        var associationId = _tenantContext.AssociationId;
        var account = await _billingService.GetBillingAccountByAssociationIdAsync(associationId);
        
        if (account == null) return NotFound(ApiResponse.FailureResponse("No billing account assigned to this association."));
        
        return Ok(ApiResponse<PlatformAccount>.SuccessResponse(account));
    }

    [HttpPost("generate-batch")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> GenerateBatch([FromBody] BillingBatchRequest request)
    {
        var count = await _billingService.GenerateMonthlyBillsAsync(request?.Month, request?.Year);
        return Ok(ApiResponse<int>.SuccessResponse(count));
    }

    [HttpPost("pay")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> PayInvoice([FromBody] PlatformPayment payment)
    {
        // Security check: ensure the invoice belongs to this association
        var invoices = await _billingService.GetInvoicesForAssociationAsync(_tenantContext.AssociationId);
        if (!invoices.Any(i => i.PlatformInvoiceId == payment.PlatformInvoiceId))
        {
            return Forbid();
        }

        var success = await _billingService.ProcessPaymentAsync(payment);
        return success ? Ok(ApiResponse.SuccessResponse("Payment successful.")) : BadRequest(ApiResponse.FailureResponse("Payment failed."));
    }

    [HttpPost("create-order/{invoiceId}")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> CreateOrder(int invoiceId)
    {
        try
        {
            var order = await _billingService.CreateOrderAsync(invoiceId);
            return Ok(ApiResponse<RazorpayOrderResponse>.SuccessResponse(order));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse(ex.Message));
        }
    }

    [HttpPost("verify-payment")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> VerifyPayment([FromBody] RazorpayVerifyRequest request)
    {
        try
        {
            var success = await _billingService.VerifyPaymentAsync(request);
            return success ? Ok(ApiResponse<bool>.SuccessResponse(true)) : BadRequest(ApiResponse<bool>.ErrorResponse("Payment verification failed."));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse.FailureResponse(ex.Message));
        }
    }
}
