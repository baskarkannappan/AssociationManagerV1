using AssociationManager.Shared.Interfaces;
using System.Threading.Tasks;
using System.Linq;
using System.Security.Claims;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Corporate.Client.Services;

public interface IAppAuthorizationService
{
    Task<bool> HasLevelAsync(ClaimsPrincipal user, int requiredLevel);
    Task<bool> IsInRoleOrHigherAsync(ClaimsPrincipal user, string role);
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

    public async Task<bool> HasLevelAsync(ClaimsPrincipal user, int requiredLevel)
    {
        if (user.Identity?.IsAuthenticated != true) return false;

        var workflowName = requiredLevel switch
        {
            90 => "RequireAdmin",
            80 => "RequireAssociationAdmin",
            60 => "RequireAssetManager",
            50 => "RequireUserManager",
            40 => "RequireManagement",
            10 => "RequireResident",
            _ => "RequireResident"
        };

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", user.FindAll(ClaimTypes.Role).Select(c => c.Value)),
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
