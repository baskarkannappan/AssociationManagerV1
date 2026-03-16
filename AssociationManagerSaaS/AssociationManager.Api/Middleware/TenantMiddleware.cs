using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using System.Linq;

namespace AssociationManager.Api.Middleware
{
    public class TenantMiddleware
    {
        private readonly RequestDelegate _next;

        public TenantMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var tenantIdClaim = context.User.Claims.FirstOrDefault(c => c.Type == "TenantId")?.Value;

            if (!string.IsNullOrEmpty(tenantIdClaim) && int.TryParse(tenantIdClaim, out int tenantId))
            {
                context.Items["TenantId"] = tenantId;
            }
            // Optional: resolve from header if not in token (for initial setup)
            else if (context.Request.Headers.TryGetValue("X-Tenant-Id", out var headerTenantId))
            {
                if (int.TryParse(headerTenantId, out int hTenantId))
                {
                    context.Items["TenantId"] = hTenantId;
                }
            }

            await _next(context);
        }
    }
}
