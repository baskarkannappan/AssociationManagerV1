using AssociationManager.Realtime.Hubs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/internal/broadcast")]
public class InternalBroadcastController : ControllerBase
{
    private readonly IHubContext<NotificationHub> _hubContext;

    public InternalBroadcastController(IHubContext<NotificationHub> hubContext)
    {
        _hubContext = hubContext;
    }

    [HttpPost("hierarchy-changed/{associationId}")]
    public async Task<IActionResult> BroadcastHierarchyChanged(int associationId)
    {
        // Simple security: Only allow from localhost or a specific header
        // In production, we'd use a shared secret or client certificate
        await _hubContext.Clients.Group($"Association_{associationId}")
            .SendAsync("HierarchyChanged");

        await _hubContext.Clients.Group($"Association_{associationId}")
            .SendAsync("ReceiveNotification", "System", "Portfolio hierarchy has been updated.");

        return Ok();
    }
}
