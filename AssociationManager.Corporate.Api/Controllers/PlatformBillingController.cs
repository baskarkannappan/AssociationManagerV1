using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class PlatformBillingController : ControllerBase
{
    private readonly IPlatformBillingService _billingService;

    public PlatformBillingController(IPlatformBillingService billingService)
    {
        _billingService = billingService;
    }

    [HttpPost("generate-batch")]
    [Authorize(Policy = "RequirePlatformAdmin")]
    public async Task<IActionResult> GenerateBatch([FromBody] BillingBatchRequest request)
    {
        var count = await _billingService.GenerateMonthlyBillsAsync(request?.Month, request?.Year);
        return Ok(ApiResponse<int>.SuccessResponse(count));
    }

    [HttpGet("all-invoices/{associationId}")]
    [Authorize(Policy = "RequirePlatformAdmin")]
    public async Task<IActionResult> GetAllInvoices(int associationId)
    {
        IEnumerable<PlatformInvoice> invoices;
        if (associationId == 0)
        {
            invoices = await _billingService.GetAllInvoicesAsync();
        }
        else
        {
            invoices = await _billingService.GetInvoicesForAssociationAsync(associationId);
        }
        return Ok(ApiResponse<IEnumerable<PlatformInvoice>>.SuccessResponse(invoices));
    }
}
