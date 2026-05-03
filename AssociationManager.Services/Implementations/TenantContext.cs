using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Http;
using System.Linq;

namespace AssociationManager.Services.Implementations;

public class TenantContext : ITenantContext
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private int? _overrideTenantId;
    private int? _overrideAssociationId;
    private int? _overrideUserId;

    public TenantContext(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int TenantId 
    {
        get
        {
            if (_overrideTenantId.HasValue) return _overrideTenantId.Value;
            var claim = GetClaim("TenantId", "tenant_id", "tid", "tenantid");
            return int.TryParse(claim, out int id) ? id : 0;
        }
    }

    public int AssociationId 
    {
        get
        {
            if (_overrideAssociationId.HasValue) return _overrideAssociationId.Value;
            var claim = GetClaim("AssociationId", "association_id", "aid", "associationid");
            return int.TryParse(claim, out int id) ? id : 0;
        }
    }

    public string AssociationStatus => GetClaim("AssociationStatus") ?? "Active";

    public int UserId 
    {
        get
        {
            if (_overrideUserId.HasValue) return _overrideUserId.Value;
            var claim = GetClaim("UserId", "user_id", "uid", "id", "sub");
            return int.TryParse(claim, out int id) ? id : 0;
        }
    }

    public string? Email => GetClaim("email", System.Security.Claims.ClaimTypes.Email, "Email");

    public bool IsPlatformAdmin => IsInRole("PlatformAdmin");
    public bool IsSystemAdmin => IsInRole("SystemAdmin");

    public void SetContext(int tenantId, int associationId, int userId = 0)
    {
        _overrideTenantId = tenantId;
        _overrideAssociationId = associationId;
        if (userId > 0) _overrideUserId = userId;
    }

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
