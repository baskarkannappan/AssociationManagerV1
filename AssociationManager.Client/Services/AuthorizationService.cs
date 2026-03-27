using System.Security.Claims;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Client.Services;

public interface IAppAuthorizationService
{
    bool HasLevel(ClaimsPrincipal user, int requiredLevel);
    bool IsInRoleOrHigher(ClaimsPrincipal user, string role);
    int? GetUserId(ClaimsPrincipal user);
}

public class AppAuthorizationService : IAppAuthorizationService
{
    public int? GetUserId(ClaimsPrincipal user)
    {
        var idStr = user.FindFirst("UserId")?.Value;
        if (int.TryParse(idStr, out int userId)) return userId;
        return null;
    }
    public bool HasLevel(ClaimsPrincipal user, int requiredLevel)
    {
        if (user.Identity?.IsAuthenticated != true) return false;

        var roleClaims = user.FindAll(ClaimTypes.Role).Select(c => c.Value)
            .Concat(user.FindAll("Role").Select(c => c.Value))
            .Concat(user.FindAll("http://schemas.microsoft.com/ws/2008/06/identity/claims/role").Select(c => c.Value))
            .ToList();

        if (!roleClaims.Any()) return false;

        var individualRoles = roleClaims
            .SelectMany(r => r.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .ToList();

        if (!individualRoles.Any()) return false;

        var maxLevel = individualRoles.Max(r => AppRole.GetLevel(r));
        
        return maxLevel >= requiredLevel;
    }

    public bool IsInRoleOrHigher(ClaimsPrincipal user, string role)
    {
        var requiredLevel = AppRole.GetLevel(role);
        return HasLevel(user, requiredLevel);
    }
}
