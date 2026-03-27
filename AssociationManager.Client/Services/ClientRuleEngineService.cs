using AssociationManager.Shared.Interfaces;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class ClientRuleEngineService : IRuleEngineService
{
    public Task<bool> EvaluateRuleAsync(string workflowName, SecurityContext context)
    {
        // On the client, we fallback to the hardcoded level logic for UI responsiveness.
        // The real security is enforced on the server via the full RulesEngine.
        bool result = workflowName switch
        {
            "RequireAssociationAdmin" => context.UserLevel >= 80,
            "RequireAssetManager" => context.UserLevel >= 60,
            "RequireUserManager" => context.UserLevel >= 50,
            "RequireFinanceManager" => context.UserLevel >= 40,
            "RequireManagement" => context.UserLevel >= 40,
            "RequireResident" => context.UserLevel >= 10,
            "IsStaff" => context.UserLevel >= 40,
            "IsResident" => context.UserLevel <= 10 && context.UserLevel > 0,
            _ => false
        };

        return Task.FromResult(result);
    }
}
