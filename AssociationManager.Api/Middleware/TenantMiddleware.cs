using AssociationManager.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace AssociationManager.Api.Middleware;

public class TenantMiddleware
{
    private readonly RequestDelegate _next;

    public TenantMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ITenantAccessor tenantAccessor)
    {
        var tenantIdClaim = context.User.Claims.FirstOrDefault(c => c.Type == "TenantId")?.Value;

        if (int.TryParse(tenantIdClaim, out int tenantId))
        {
            tenantAccessor.TenantId = tenantId;
        }

        await _next(context);
    }
}
