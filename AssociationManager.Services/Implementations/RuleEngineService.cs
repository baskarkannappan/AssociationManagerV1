using System;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
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
            
            var results = await engine.ExecuteAllRulesAsync(workflowName, context);
            
            // If any rule in the workflow passes, we consider it successful for authorization
            return results.Any(r => r.IsSuccess);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error evaluating auth rule {WorkflowName}", workflowName);
            return false;
        }
    }
}
