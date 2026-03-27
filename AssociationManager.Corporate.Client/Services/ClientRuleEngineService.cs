using AssociationManager.Shared.Interfaces;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Client.Services;

public class ClientRuleEngineService : IRuleEngineService
{
    public Task<bool> EvaluateRuleAsync(string workflowName, SecurityContext context)
    {
        int requiredLevel = workflowName switch
        {
            "RequireAdmin" => 90,
            "RequireAssociationAdmin" => 80,
            "RequireAssetManager" => 60,
            "RequireUserManager" => 50,
            "RequireFinanceManager" => 40,
            "RequireManagement" => 40,
            "RequireResident" => 10,
            _ => 10 // Default to lowest
        };

        return Task.FromResult(context.UserLevel >= requiredLevel);
    }
}
