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
            },
            new AuthWorkflow
            {
                Name = "CanManageAsset",
                Description = "Checks if user can manage a specific asset (Staff or Primary Resident)",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "CanManageAsset",
                        Rules = new[]
                        {
                            new { RuleName = "StaffCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "True" },
                            new { RuleName = "ResidentCheck", Expression = "input1.UserLevel >= 10 AND input1.IsPrimaryResident == true", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "CanViewAsset",
                Description = "Checks if user can view a specific asset",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new {
                        WorkflowName = "CanViewAsset",
                        Rules = new[]
                        {
                            new { RuleName = "StaffCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "True" },
                            new { RuleName = "ResidentCheck", Expression = "input1.UserLevel >= 10 AND input1.IsPrimaryResident == true", SuccessEvent = "True" }
                        }
                    }
                })
            },
            // --- MENU VISIBILITY WORKFLOWS ---
            new AuthWorkflow
            {
                Name = "ShowMenu_Assets",
                Description = "Controls visibility of the Assets menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Assets",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Finance",
                Description = "Controls visibility of the Finance menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Finance",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Operations",
                Description = "Controls visibility of the Operations menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Operations",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Users",
                Description = "Controls visibility of the User & Roles menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Users",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 80", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Tariffs",
                Description = "Controls visibility of the Tariff Management menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Tariffs",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Community",
                Description = "Controls visibility of the Community menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Community",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 80", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Broadcasts",
                Description = "Controls visibility of the Communication menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Broadcasts",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Governance",
                Description = "Controls visibility of the Governance section",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Governance",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowMenu_Settings",
                Description = "Controls visibility of the Settings menu item",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowMenu_Settings",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 90", SuccessEvent = "True" }
                        }
                    }
                })
            },
            // --- DASHBOARD WIDGET WORKFLOWS ---
            new AuthWorkflow
            {
                Name = "ShowWidget_FinancialSummary",
                Description = "Controls visibility of the Financial Summary tile on the dashboard",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowWidget_FinancialSummary",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowWidget_ActiveRequests",
                Description = "Controls visibility of the Active Requests tile on the dashboard",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowWidget_ActiveRequests",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowWidget_Announcements",
                Description = "Controls visibility of the Announcements tile on the dashboard",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowWidget_Announcements",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowWidget_AuditLog",
                Description = "Controls visibility of the Recent Activity / Audit Log on the dashboard",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowWidget_AuditLog",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 60", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowWidget_Committee",
                Description = "Controls visibility of the Committee tile on the dashboard",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowWidget_Committee",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 10", SuccessEvent = "True" }
                        }
                    }
                })
            },
            new AuthWorkflow
            {
                Name = "ShowWidget_Outstanding",
                Description = "Controls visibility of the Total Outstanding tile (Admin)",
                WorkflowJson = JsonSerializer.Serialize(new[]
                {
                    new
                    {
                        WorkflowName = "ShowWidget_Outstanding",
                        Rules = new[]
                        {
                            new { RuleName = "AccessCheck", Expression = "input1.UserLevel >= 40", SuccessEvent = "True" }
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
