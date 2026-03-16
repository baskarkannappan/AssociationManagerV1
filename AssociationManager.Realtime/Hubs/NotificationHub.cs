using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;

namespace AssociationManager.Realtime.Hubs
{
    public class NotificationHub : Hub
    {
        public async Task JoinTenantGroup(int tenantId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"Tenant_{tenantId}");
        }

        public async Task LeaveTenantGroup(int tenantId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Tenant_{tenantId}");
        }

        public async Task SendMessageToTenant(int tenantId, string message)
        {
            await Clients.Group($"Tenant_{tenantId}").SendAsync("ReceiveNotification", message);
        }
    }
}
