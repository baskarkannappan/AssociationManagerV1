using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Linq;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;

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
        var roleClaims = context.User.Claims.Where(c => 
            c.Type == "role" || 
            c.Type == ClaimTypes.Role || 
            c.Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role");

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roleClaims.Select(c => c.Value)),
            UserLevel = AppRole.GetMaxLevel(context.User.Claims),
            AssociationId = _tenantContext.AssociationId,
            IsOwner = false 
        };

        // 2. Use Workflow Name from requirement, with a smarter fallback
        string workflowName = requirement.WorkflowName;
        if (string.IsNullOrEmpty(workflowName))
        {
            if (requirement.RequiredLevel >= 80) workflowName = "RequireAssociationAdmin";
            else if (requirement.RequiredLevel >= 40) workflowName = "RequireManagement";
            else workflowName = "RequireResident";
        }

        // 3. Evaluate Rule
        var isAuthorized = await _ruleEngine.EvaluateRuleAsync(workflowName, securityContext);

        if (isAuthorized)
        {
            context.Succeed(requirement);
        }
    }
}
