using AssociationManager.Shared.Interfaces;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class ClientRuleEngineService : IRuleEngineService
{
    public Task<bool> EvaluateRuleAsync(string workflowName, SecurityContext context)
    {
        // On the client, we fallback to the hardcoded level logic for UI responsiveness.
        // The real security is enforced on the server via the full RulesEngine.
        int requiredLevel = workflowName switch
        {
            "RequireAssociationAdmin" => 80,
            "RequireAssetManager" => 60,
            "RequireUserManager" => 50,
            "RequireFinanceManager" => 40,
            "RequireManagement" => 40,
            "RequireResident" => 10,
            _ => 0
        };

        return Task.FromResult(context.UserLevel >= requiredLevel);
    }
}
