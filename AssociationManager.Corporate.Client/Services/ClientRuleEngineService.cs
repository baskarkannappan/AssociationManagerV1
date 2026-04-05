using System;
using AssociationManager.Shared.Interfaces;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Client.Services;

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

        bool result = workflowName switch
        {
            "RequireAdmin" => context.UserLevel >= 90,
            "RequireAssociationAdmin" => context.UserLevel >= 80,
            "RequireAssetManager" => context.UserLevel >= 60,
            "RequireUserManager" => context.UserLevel >= 50,
            "RequireFinanceManager" => context.UserLevel >= 40,
            "RequireManagement" => context.UserLevel >= 40,
            "RequireResident" => context.UserLevel >= 10,
            _ => false // Default to false if unknown
        };

        return Task.FromResult(result);
    }

    public Task<decimal> CalculateValueAsync(string workflowName, FineCalculationContext context)
    {
        // On the corporate client, we use the server-calculated values for fines.
        // This is a standardized C# backup for UI-side logic matching the Association client.
        if (!workflowName.StartsWith("FineRule_")) return Task.FromResult(0m);

        decimal result = workflowName switch
        {
            "FineRule_FlatAmount" => context.FlatAmount * context.MonthsLate,
            "FineRule_OneTimeFlat" => context.FlatAmount,
            "FineRule_Percentage" when context.IsCompounding => (decimal)Math.Pow((double)(1 + context.Rate), context.MonthsLate) * context.OriginalAmount - context.OriginalAmount,
            "FineRule_Percentage" when !context.IsCompounding => context.OriginalAmount * context.Rate * context.MonthsLate,
            "FineRule_OneTimePercentage" => context.OriginalAmount * context.Rate,
            _ => 0m
        };

        return Task.FromResult(Math.Round(result, 2));
    }
}
