using System.Security.Claims;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Corporate.Client.Services;

public interface IAppAuthorizationService
{
    bool HasLevel(ClaimsPrincipal user, int requiredLevel);
    bool IsInRoleOrHigher(ClaimsPrincipal user, string role);
}

public class AppAuthorizationService : IAppAuthorizationService
{
    public bool HasLevel(ClaimsPrincipal user, int requiredLevel)
    {
        if (user.Identity?.IsAuthenticated != true) return false;

        var roleClaim = user.FindFirst(ClaimTypes.Role)?.Value;
        var userLevel = AppRole.GetLevel(roleClaim);
        
        return userLevel >= requiredLevel;
    }

    public bool IsInRoleOrHigher(ClaimsPrincipal user, string role)
    {
        var requiredLevel = AppRole.GetLevel(role);
        return HasLevel(user, requiredLevel);
    }
}
