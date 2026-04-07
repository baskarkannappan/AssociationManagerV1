using System;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.Extensions.Logging;
using RulesEngine.Models;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class RuleEngineService : IRuleEngineService
{
    private readonly IAuthWorkflowRepository _workflowRepository;
    private readonly ILogger<RuleEngineService> _logger;

    public RuleEngineService(IAuthWorkflowRepository workflowRepository, ILogger<RuleEngineService> logger)
    {
        _workflowRepository = workflowRepository;
        _logger = logger;
    }

    public async Task<bool> EvaluateRuleAsync(string workflowName, SecurityContext context)
    {
        try
        {
            var workflow = await _workflowRepository.GetByNameAsync(workflowName);
            if (workflow == null)
            {
                _logger.LogWarning("Auth Workflow {WorkflowName} not found in database.", workflowName);
                return false;
            }

            var workflowData = JsonSerializer.Deserialize<List<Workflow>>(workflow.WorkflowJson);
            if (workflowData == null) return false;

            var engine = new RulesEngine.RulesEngine(workflowData.ToArray());
            
            // Hard gate: If association is deactivated, only Admins have any access
            if (context.AssociationStatus == "Deactivated" && 
                !context.UserRole.Contains("AssociationAdmin") && 
                !context.UserRole.Contains("PlatformAdmin"))
            {
                return false;
            }

            var results = await engine.ExecuteAllRulesAsync(workflowName, context);
            
            // If association is deactivated, even Admins are restricted to Read access
            // (Note: This logic can be more granular per workflow if needed)
            if (context.AssociationStatus == "Deactivated" && 
                (workflowName.Contains("Create") || workflowName.Contains("Update") || workflowName.Contains("Delete") || workflowName.Contains("Add") || workflowName.Contains("Process")))
            {
                // Only allow Read-only operations if association is deactivated
                return false;
            }

            // If any rule in the workflow passes, we consider it successful for authorization
            return results.Any(r => r.IsSuccess);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error evaluating auth rule {WorkflowName}", workflowName);
            return false;
        }
    }

    public async Task<decimal> CalculateValueAsync(string workflowName, FineCalculationContext context)
    {
        try
        {
            var workflow = await _workflowRepository.GetByNameAsync(workflowName);
            if (workflow == null) return 0m;

            var workflowData = JsonSerializer.Deserialize<List<Workflow>>(workflow.WorkflowJson);
            if (workflowData == null) return 0m;

            var engine = new RulesEngine.RulesEngine(workflowData.ToArray());
            var results = await engine.ExecuteAllRulesAsync(workflowName, context);
            
            var successRule = results.FirstOrDefault(r => r.IsSuccess);
            if (successRule != null && decimal.TryParse(successRule.Rule.SuccessEvent, out decimal val))
            {
                return val;
            }
            
            return 0m;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating fine value for {WorkflowName}", workflowName);
            return 0m;
        }
    }
}
