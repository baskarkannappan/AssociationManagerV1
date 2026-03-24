using Microsoft.AspNetCore.Authorization;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class RoleRequirement : IAuthorizationRequirement
{
    public List<string> AllowedRoles { get; }

    public RoleRequirement(params string[] roles)
    {
        AllowedRoles = new List<string>(roles);
    }
}
