using Microsoft.AspNetCore.Authorization;

namespace AssociationManager.Shared.Authorization;

public class RoleLevelRequirement : IAuthorizationRequirement
{
    public int RequiredLevel { get; }

    public RoleLevelRequirement(int requiredLevel)
    {
        RequiredLevel = requiredLevel;
    }
}
