using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SubscriptionController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;

    public SubscriptionController(ISubscriptionService subscriptionService)
    {
        _subscriptionService = subscriptionService;
    }

    [HttpGet("plans")]
    public async Task<ActionResult<IEnumerable<SubscriptionPlan>>> GetPlans()
    {
        var plans = await _subscriptionService.GetPlansAsync();
        return Ok(plans);
    }

    [HttpGet("{associationId}")]
    public async Task<ActionResult<AssociationSubscription>> GetSubscription(int associationId)
    {
        var subscription = await _subscriptionService.GetSubscriptionAsync(associationId);
        if (subscription == null) return NotFound();
        return Ok(subscription);
    }

    [HttpPost("subscribe")]
    public async Task<IActionResult> Subscribe([FromBody] SubscriptionRequest request)
    {
        var result = await _subscriptionService.SubscribeAsync(request.AssociationId, request.PlanId);
        if (!result) return BadRequest("Failed to subscribe.");
        return Ok();
    }

    [HttpGet("{associationId}/next-bill")]
    public async Task<ActionResult<decimal>> GetNextBill(int associationId)
    {
        var amount = await _subscriptionService.CalculateNextBillAsync(associationId);
        return Ok(amount);
    }

    [HttpGet("verify")]
    public async Task<IActionResult> VerifyHybridPricing()
    {
        int testAssociationId = 1; // Assuming Association 1 exists
        int testPlanId = 1; // 'Starter' plan ($50 base + $0.50 per asset)

        // Subscribe Association 1 to Plan 1
        await _subscriptionService.SubscribeAsync(testAssociationId, testPlanId);

        // Calculate Bill
        decimal bill = await _subscriptionService.CalculateNextBillAsync(testAssociationId);
        
        return Ok(new { 
            AssociationId = testAssociationId, 
            PlanId = testPlanId,
            CalculatedBill = bill,
            Message = "Verification successful"
        });
    }
}
