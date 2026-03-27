using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AuthWorkflowRepository : IAuthWorkflowRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public AuthWorkflowRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<AuthWorkflow?> GetByNameAsync(string name)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<AuthWorkflow>(
            "assoc.sp_AuthWorkflows_GetByName",
            new { Name = name },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpsertAsync(AuthWorkflow workflow)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_AuthWorkflows_Upsert",
            new { 
                Name = workflow.Name, 
                WorkflowJson = workflow.WorkflowJson, 
                Description = workflow.Description 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<AuthWorkflow>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AuthWorkflow>(
            "SELECT * FROM assoc.AuthWorkflows",
            commandType: CommandType.Text);
    }
}
