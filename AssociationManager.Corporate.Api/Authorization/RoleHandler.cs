using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Linq;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Corporate.Api.Authorization;

public class RoleHandler : AuthorizationHandler<RoleRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, RoleRequirement requirement)
    {
        // 1. Manually find all potential role claims
        var roleClaims = context.User.FindAll("role")
            .Concat(context.User.FindAll(ClaimTypes.Role))
            .Concat(context.User.FindAll("Role"))
            .Concat(context.User.FindAll("http://schemas.microsoft.com/ws/2008/06/identity/claims/role"))
            .Select(c => c.Value)
            .ToList();

        if (roleClaims.Any())
        {
            // 2. Split comma-separated roles if any
            var individualRoles = roleClaims
                .SelectMany(r => r.Split(',', System.StringSplitOptions.RemoveEmptyEntries | System.StringSplitOptions.TrimEntries))
                .ToList();

            // 3. Check if any of the target roles are present
            if (individualRoles.Any(r => requirement.AllowedRoles.Contains(r)))
            {
                context.Succeed(requirement);
            }
        }

        return Task.CompletedTask;
    }
}
