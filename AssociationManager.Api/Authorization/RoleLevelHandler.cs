using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Api.Authorization;

public class RoleLevelHandler : AuthorizationHandler<RoleLevelRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, RoleLevelRequirement requirement)
    {
        var roleClaim = context.User.FindFirst(ClaimTypes.Role)?.Value 
                     ?? context.User.FindFirst("Role")?.Value 
                     ?? context.User.FindFirst("http://schemas.microsoft.com/ws/2008/06/identity/claims/role")?.Value;

        if (string.IsNullOrEmpty(roleClaim))
        {
            return Task.CompletedTask;
        }

        var userLevel = AppRole.GetLevel(roleClaim);

        if (userLevel >= requirement.RequiredLevel)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
