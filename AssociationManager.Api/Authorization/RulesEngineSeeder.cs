using AssociationManager.Data.Interfaces;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;

namespace AssociationManager.Api.Authorization;

public class RulesEngineSeeder
{
    private readonly IAuthWorkflowRepository _workflowRepository;

    public RulesEngineSeeder(IAuthWorkflowRepository workflowRepository)
    {
        _workflowRepository = workflowRepository;
    }

    public async Task SeedAsync()
    {
        var workflows = new List<AuthWorkflow>
        {
            new AuthWorkflow
            {
                Name = "RequireAssociationAdmin",
                Description = "Requires level 80 or higher",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "RequireAssociationAdmin",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel >= 80", SuccessEvent = "Authorized" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "RequireManagement",
                Description = "Requires level 40 or higher",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "RequireManagement",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "Authorized" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "RequireResident",
                Description = "Requires level 10 or higher",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "RequireResident",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "Authorized" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "RequireFinanceManager",
                Description = "Requires level 40 or higher",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "RequireFinanceManager",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "Authorized" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "RequireUserManager",
                Description = "Requires level 50 or higher",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "RequireUserManager",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel >= 50", SuccessEvent = "Authorized" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "IsStaff",
                Description = "Checks if the user is a staff member (level 40+)",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "IsStaff",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "IsResident",
                Description = "Checks if the user is a resident (level 10)",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "IsResident",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel <= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "RequireAdmin",
                Description = "Requires level 90 or higher (System/Platform Admin)",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "RequireAdmin",
                        Rules = new[]
                        {
                            new { RuleName = "LevelCheck", Expression = "input1.UserLevel >= 90", SuccessEvent = "True" }
                        }
                    }
                })
            }
        };

        foreach (var workflow in workflows)
        {
            await _workflowRepository.UpsertAsync(workflow);
        }
    }
}
