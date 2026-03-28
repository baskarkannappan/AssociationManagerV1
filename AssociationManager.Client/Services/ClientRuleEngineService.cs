using AssociationManager.Shared.Interfaces;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class ClientRuleEngineService : IRuleEngineService
{
    public Task<bool> EvaluateRuleAsync(string workflowName, SecurityContext context)
    {
        // On the client, we use level-based logic for UI responsiveness.
        // Special mapping for Menu and Widget visibility policies
        if (workflowName.StartsWith("ShowMenu_") || workflowName.StartsWith("ShowWidget_"))
        {
            int required = workflowName switch
            {
                "ShowMenu_Settings" => 90,
                "ShowMenu_Users" or "ShowMenu_Community" => 80,
                "ShowWidget_AuditLog" => 60,
                "ShowMenu_Tariffs" or "ShowMenu_Broadcasts" or "ShowWidget_Outstanding" => 40,
                _ => 10 // Most menus/widgets are visible to residents (Level 10)
            };
            return Task.FromResult(context.UserLevel >= required);
        }

        // Standard functional requirements
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
