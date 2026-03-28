using Microsoft.AspNetCore.Authorization;

namespace AssociationManager.Shared.Authorization;

public class RoleLevelRequirement : IAuthorizationRequirement
{
    public int RequiredLevel { get; }
    public string WorkflowName { get; }

    public RoleLevelRequirement(int requiredLevel, string workflowName = "")
    {
        RequiredLevel = requiredLevel;
        WorkflowName = workflowName;
    }
}
