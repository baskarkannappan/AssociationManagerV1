using System;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services
{
    public class EventBusService
    {
        public event Func<Task>? OnGlobalRefreshRequested;
        public event Func<int, int, Task>? OnTenantSwitched;

        public async Task RequestGlobalRefresh()
        {
            if (OnGlobalRefreshRequested != null)
            {
                await OnGlobalRefreshRequested.Invoke();
            }
        }

        public async Task NotifyTenantSwitched(int tenantId, int associationId)
        {
            if (OnTenantSwitched != null)
            {
                await OnTenantSwitched.Invoke(tenantId, associationId);
            }
        }
    }
}
