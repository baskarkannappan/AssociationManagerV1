namespace AssociationManager.Shared.Interfaces;

public class SecurityContext
{
    public string UserRole { get; set; } = string.Empty;
    public int UserLevel { get; set; }
    public bool IsOwner { get; set; }
    public string Action { get; set; } = string.Empty;
    public string Resource { get; set; } = string.Empty;
    public int AssociationId { get; set; }
}

public interface IRuleEngineService
{
    Task<bool> EvaluateRuleAsync(string workflowName, SecurityContext context);
}
