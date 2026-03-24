using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Api.Authorization;

public class RoleLevelHandler : AuthorizationHandler<RoleLevelRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, RoleLevelRequirement requirement)
    {
        var roleClaims = context.User.FindAll(ClaimTypes.Role).Select(c => c.Value)
            .Concat(context.User.FindAll("role").Select(c => c.Value))
            .Concat(context.User.FindAll("Role").Select(c => c.Value))
            .Concat(context.User.FindAll("http://schemas.microsoft.com/ws/2008/06/identity/claims/role").Select(c => c.Value))
            .ToList();

        if (roleClaims.Any())
        {
            var individualRoles = roleClaims
                .SelectMany(r => r.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                .ToList();

            if (individualRoles.Any())
            {
                var maxLevel = individualRoles.Max(r => AppRole.GetLevel(r));
                if (maxLevel >= requirement.RequiredLevel)
                {
                    context.Succeed(requirement);
                }
            }
        }

        return Task.CompletedTask;
    }
}
