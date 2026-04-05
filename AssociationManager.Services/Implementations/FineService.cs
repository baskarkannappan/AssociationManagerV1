using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class FineService : IFineService
{
    private readonly IFineRepository _fineRepository;
    private readonly IRuleEngineService _ruleEngine;

    public FineService(IFineRepository fineRepository, IRuleEngineService ruleEngine)
    {
        _fineRepository = fineRepository;
        _ruleEngine = ruleEngine;
    }

    public async Task<decimal> CalculateFineAsync(Invoice invoice, DateTime atDate)
    {
        if (invoice.DueDate >= atDate) return 0m;

        var settings = await _fineRepository.GetByAssociationIdAsync(invoice.AssociationId);
        if (settings == null || settings.StrategyType == "None") return 0m;

        var daysLate = (atDate - invoice.DueDate).Days;
        if (daysLate <= settings.GracePeriodDays) return 0m;

        // Calculate Months Late (Ceiling)
        int monthsLate = (int)Math.Ceiling(daysLate / 30.44); // Average month length

        var context = new FineCalculationContext
        {
            OriginalAmount = invoice.Amount,
            DaysLate = daysLate,
            MonthsLate = monthsLate,
            Rate = settings.FineValue / 100, // Convert percentage if applicable
            FlatAmount = settings.FineValue,
            IsCompounding = settings.IsCompounding
        };

        // We use a standardized workflow name format: "FineRule_{StrategyType}"
        // OR a per-association override: "FineRule_Assoc_{Id}"
        string workflowName = $"FineRule_{settings.StrategyType}";
        
        // If it's a compounding percentage, we use a specific math formula
        if (settings.StrategyType == "Percentage" && settings.IsCompounding)
        {
            // Total = P * (1 + r)^n - P (to get only the fine)
            return Math.Round(invoice.Amount * (decimal)Math.Pow((double)(1 + context.Rate), monthsLate) - invoice.Amount, 2);
        }

        // For other rules, we leverage the Rule Engine if a specific association workflow exists
        // Fallback to basic calculation if no specific rule is found
        return settings.StrategyType switch
        {
            "FlatAmount" => settings.FineValue * monthsLate,
            "OneTimeFlat" => settings.FineValue,
            "OneTimePercentage" => Math.Round(invoice.Amount * context.Rate, 2),
            "Percentage" when !settings.IsCompounding => Math.Round(invoice.Amount * context.Rate * monthsLate, 2),
            _ => 0m
        };
    }

    public async Task<FineSettings?> GetSettingsAsync(int associationId)
    {
        return await _fineRepository.GetByAssociationIdAsync(associationId);
    }

    public async Task SaveSettingsAsync(FineSettings settings)
    {
        // Here we could also generate the RulesEngine JSON if we wanted to override the default C# logic
        await _fineRepository.UpsertAsync(settings, settings.AssociationId); // Using ID as stub for UserId for now
    }
}
