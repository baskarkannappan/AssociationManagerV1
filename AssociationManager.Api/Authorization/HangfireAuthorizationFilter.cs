using Hangfire.Dashboard;
using Microsoft.AspNetCore.Http;

namespace AssociationManager.Api.Authorization
{
    public class HangfireAuthorizationFilter : IDashboardAuthorizationFilter
    {
        public bool Authorize(DashboardContext context)
        {
            // In development/test, we can allow access. 
            // In a production app, you would check for a specific role like 'SystemAdmin'.
            return true; 
        }
    }
}
