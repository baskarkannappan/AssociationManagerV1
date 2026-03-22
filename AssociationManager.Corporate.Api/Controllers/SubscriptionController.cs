using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Api.Controllers;

[Authorize]
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
    [Authorize(Policy = "RequireCorporate")]
    public async Task<IActionResult> GetPlans()
    {
        var plans = await _subscriptionService.GetPlansAsync();
        return Ok(ApiResponse<IEnumerable<SubscriptionPlan>>.SuccessResponse(plans));
    }

    [HttpGet("{associationId}")]
    [Authorize(Policy = "RequireCorporate")]
    public async Task<IActionResult> GetSubscription(int associationId)
    {
        var subscription = await _subscriptionService.GetSubscriptionAsync(associationId);
        if (subscription == null) return NotFound(ApiResponse.FailureResponse("Subscription not found."));
        return Ok(ApiResponse<AssociationSubscription>.SuccessResponse(subscription));
    }

    [HttpPost("subscribe")]
    [Authorize(Policy = "RequireManagement")]
    public async Task<IActionResult> Subscribe([FromBody] SubscriptionRequest request)
    {
        var result = await _subscriptionService.SubscribeAsync(request.AssociationId, request.PlanId);
        if (!result) return BadRequest(ApiResponse.FailureResponse("Failed to subscribe."));
        return Ok(ApiResponse.SuccessResponse("Subscribed successfully."));
    }

    [HttpGet("{associationId}/next-bill")]
    [Authorize(Policy = "RequireCorporate")]
    public async Task<IActionResult> GetNextBill(int associationId)
    {
        var amount = await _subscriptionService.CalculateNextBillAsync(associationId);
        return Ok(ApiResponse<decimal>.SuccessResponse(amount));
    }

    [HttpGet("summary")]
    [Authorize(Policy = "RequireCorporate")]
    public async Task<IActionResult> GetSummary()
    {
        var summary = await _subscriptionService.GetAllSubscriptionsAsync();
        return Ok(ApiResponse<IEnumerable<AssociationSubscription>>.SuccessResponse(summary));
    }

    [HttpPost("plans")]
    [Authorize(Policy = "RequirePlanManagement")]
    public async Task<IActionResult> SavePlan([FromBody] SubscriptionPlan plan)
    {
        var result = await _subscriptionService.SavePlanAsync(plan);
        if (!result) return BadRequest(ApiResponse.FailureResponse("Failed to save plan."));
        return Ok(ApiResponse.SuccessResponse("Plan saved successfully."));
    }
}
