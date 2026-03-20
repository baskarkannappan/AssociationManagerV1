using Microsoft.AspNetCore.Authorization;

namespace AssociationManager.Api.Authorization;

public class RoleLevelRequirement : IAuthorizationRequirement
{
    public int RequiredLevel { get; }

    public RoleLevelRequirement(int requiredLevel)
    {
        RequiredLevel = requiredLevel;
    }
}
