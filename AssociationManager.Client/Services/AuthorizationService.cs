using AssociationManager.Shared.Interfaces;
using System.Threading.Tasks;
using System.Linq;
using System.Security.Claims;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Client.Services;

public interface IAppAuthorizationService
{
    Task<bool> HasLevelAsync(ClaimsPrincipal user, int requiredLevel);
    Task<bool> IsInRoleOrHigherAsync(ClaimsPrincipal user, string role);
    int? GetUserId(ClaimsPrincipal user);
}

public class AppAuthorizationService : IAppAuthorizationService
{
    private readonly IRuleEngineService _ruleEngine;
    private readonly ITenantContext _tenantContext;

    public AppAuthorizationService(IRuleEngineService ruleEngine, ITenantContext tenantContext)
    {
        _ruleEngine = ruleEngine;
        _tenantContext = tenantContext;
    }

    public int? GetUserId(ClaimsPrincipal user)
    {
        var idStr = user.FindFirst("UserId")?.Value;
        if (int.TryParse(idStr, out int userId)) return userId;
        return null;
    }

    public async Task<bool> HasLevelAsync(ClaimsPrincipal user, int requiredLevel)
    {
        if (user.Identity?.IsAuthenticated != true) return false;

        var workflowName = requiredLevel switch
        {
            90 => "RequireAdmin",
            80 => "RequireAssociationAdmin",
            60 => "RequireAssetManager",
            50 => "RequireUserManager",
            40 => "RequireFinanceManager",
            10 => "RequireResident",
            _ => "RequireResident"
        };

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", user.Claims.Where(c => c.Type == "role" || c.Type == ClaimTypes.Role || c.Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role").Select(c => c.Value)),
            UserLevel = AppRole.GetMaxLevel(user.Claims),
            AssociationId = _tenantContext.AssociationId
        };

        return await _ruleEngine.EvaluateRuleAsync(workflowName, securityContext);
    }

    public async Task<bool> IsInRoleOrHigherAsync(ClaimsPrincipal user, string role)
    {
        var requiredLevel = AppRole.GetLevel(role);
        return await HasLevelAsync(user, requiredLevel);
    }
}
