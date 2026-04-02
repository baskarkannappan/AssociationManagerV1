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
            var claim = GetClaim("TenantId", "tenant_id", "tid", "tenantid");
            return int.TryParse(claim, out int id) ? id : 0;
        }
    }

    public int AssociationId 
    {
        get
        {
            var claim = GetClaim("AssociationId", "association_id", "aid", "associationid");
            return int.TryParse(claim, out int id) ? id : 0;
        }
    }

    public int UserId 
    {
        get
        {
            var claim = GetClaim("UserId", "user_id", "uid", "id", "sub");
            return int.TryParse(claim, out int id) ? id : 0;
        }
    }

    public string? Email => GetClaim("email", System.Security.Claims.ClaimTypes.Email, "Email");

    public bool IsPlatformAdmin => IsInRole("PlatformAdmin");
    public bool IsSystemAdmin => IsInRole("SystemAdmin");

    private string? GetClaim(params string[] types)
    {
        var user = _httpContextAccessor.HttpContext?.User;
        if (user == null) return null;
        
        foreach (var type in types)
        {
            var claim = user.FindFirst(type)?.Value;
            if (!string.IsNullOrEmpty(claim)) return claim;
        }
        return null;
    }

    private bool IsInRole(string role)
    {
        var user = _httpContextAccessor.HttpContext?.User;
        if (user == null) return false;

        // Check standard IsInRole AND manual claim search for "role"
        if (user.IsInRole(role)) return true;
        
        return user.Claims.Any(c => 
            (c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role) 
            && c.Value.Equals(role, System.StringComparison.OrdinalIgnoreCase));
    }
}
