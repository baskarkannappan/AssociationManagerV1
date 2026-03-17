using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Http;
using System.Linq;

namespace AssociationManager.Services.Implementations;

public class TenantContext : ITenantContext
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public TenantContext(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int TenantId
    {
        get
        {
            var claim = _httpContextAccessor.HttpContext?.User?.Claims
                .FirstOrDefault(c => c.Type == "TenantId")?.Value;
            return int.TryParse(claim, out int tenantId) ? tenantId : 0;
        }
    }

    public int UserId
    {
        get
        {
            var claim = _httpContextAccessor.HttpContext?.User?.Claims
                .FirstOrDefault(c => c.Type == "UserId")?.Value;
            return int.TryParse(claim, out int userId) ? userId : 0;
        }
    }
}
