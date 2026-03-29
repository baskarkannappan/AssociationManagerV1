using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class SubscriptionController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;
    private readonly ITenantContext _tenantContext;

    public SubscriptionController(ISubscriptionService subscriptionService, ITenantContext tenantContext)
    {
        _subscriptionService = subscriptionService;
        _tenantContext = tenantContext;
    }

    [HttpGet("current")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> GetCurrentSubscription()
    {
        var subscription = await _subscriptionService.GetSubscriptionAsync(_tenantContext.AssociationId);
        if (subscription == null) return NotFound(ApiResponse.FailureResponse("No active subscription."));
        return Ok(ApiResponse<AssociationSubscription>.SuccessResponse(subscription));
    }
}
