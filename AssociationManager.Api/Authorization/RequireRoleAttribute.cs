using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System;
using System.Linq;

namespace AssociationManager.Api.Authorization;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class RequireRoleAttribute : Attribute, IAuthorizationFilter
{
    private readonly string[] _roles;

    public RequireRoleAttribute(params string[] roles)
    {
        _roles = roles;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;
        if (!user.Identity?.IsAuthenticated ?? true)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        var userRoles = user.Claims.Where(c => c.Type == "role" || c.Type == "Role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                                   .Select(c => c.Value).ToList();
        
        if (!userRoles.Any(r => _roles.Contains(r)))
        {
            // SystemAdmin bypasses role checks 
            if (userRoles.Contains("SystemAdmin") || userRoles.Contains("PlatformAdmin")) return;

            context.Result = new ForbidResult();
        }
    }
}
