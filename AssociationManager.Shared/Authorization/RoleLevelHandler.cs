using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Linq;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;

namespace AssociationManager.Shared.Authorization;

public class RoleLevelHandler : AuthorizationHandler<RoleLevelRequirement>
{
    private readonly IRuleEngineService _ruleEngine;
    private readonly ITenantContext _tenantContext;

    public RoleLevelHandler(IRuleEngineService ruleEngine, ITenantContext tenantContext)
    {
        _ruleEngine = ruleEngine;
        _tenantContext = tenantContext;
    }

    protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, RoleLevelRequirement requirement)
    {
        // 1. Prepare Security Context
        var roles = context.User.Claims.Where(c => c.Type == "role" || c.Type == ClaimTypes.Role)
                                      .Select(c => c.Value);

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roles),
            UserLevel = AppRole.GetMaxLevel(context.User.Claims),
            AssociationId = _tenantContext.AssociationId,
            IsOwner = false // This could be filled by a more complex pre-check if needed
        };

        // 2. Determine Workflow Name based on Requirement Level (Mapping hardcoded policies to workflows)
        string workflowName = requirement.RequiredLevel switch
        {
            80 => "RequireAssociationAdmin",
            60 => "RequireAssetManager",
            50 => "RequireUserManager",
            40 => "RequireFinanceManager",
            10 => "RequireResident",
            _ => "RequireResident"
        };

        // 3. Evaluate Rule
        var isAuthorized = await _ruleEngine.EvaluateRuleAsync(workflowName, securityContext);
        
        if (isAuthorized)
        {
            context.Succeed(requirement);
        }
    }
}
