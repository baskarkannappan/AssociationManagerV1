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
        // 0. FAST-TRACK BYPASS: PlatformAdmins pass everything without needing services or DB checks
        var roles = context.User.Claims.Where(c => c.Type == "role" || c.Type == ClaimTypes.Role || c.Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role").Select(c => c.Value).ToList();
        var userLevel = AppRole.GetMaxLevel(context.User.Claims);
        
        System.Console.WriteLine($"[AUTH-DEBUG] Checking Policy: {requirement.WorkflowName}, Level Req: {requirement.RequiredLevel}, User Level: {userLevel}");
        System.Console.WriteLine($"[AUTH-DEBUG] User Roles: {string.Join(", ", roles)}");

        if (roles.Contains(AppRole.PlatformAdmin) || context.User.HasClaim("role", AppRole.PlatformAdmin))
        {
            context.Succeed(requirement);
            return;
        }

        // 1. Prepare Security Context for other roles...
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

        // 3. Evaluation Logic
        // 3a. FAST PATH: If direct role level is already sufficient, succeed immediately.
        // This removes dependency on database rules for basic hierarchy-based access.
        if (securityContext.UserLevel >= requirement.RequiredLevel)
        {
            context.Succeed(requirement);
            return;
        }

        // 3b. RULE ENGINE: Use for complex/overridden rules if level check didn't pass or for specific workflows
        var isAuthorized = await _ruleEngine.EvaluateRuleAsync(workflowName, securityContext);

        if (isAuthorized)
        {
            context.Succeed(requirement);
        }
    }
}
