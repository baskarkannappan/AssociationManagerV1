using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AssociationRepository : IAssociationRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;
    private readonly string _schema;

    public AssociationRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext, string schema = "corp")
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
        _schema = schema;
    }

    public async Task<Association?> GetByIdAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Association>(
            "corp.sp_Associations_GetById", 
            new { Id = id, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Association>> GetAllByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            "corp.sp_Associations_GetAllByTenantId", 
            new { TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Association association)
    {
        association.TenantId = _tenantContext.TenantId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_Associations_Create", 
            new 
            { 
                association.TenantId, 
                association.Name, 
                association.Description, 
                association.CreatedDate, 
                association.CreatedBy 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Association association)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Associations_Update", 
            new 
            { 
                association.AssociationId, 
                association.TenantId, 
                association.Name, 
                association.Description 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Associations_Delete", 
            new { Id = id, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<Association>> GetByUserIdAsync(int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            $"{_schema}.sp_Associations_GetByUserId", 
            new { UserId = userId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Association>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            "SELECT * FROM corp.Associations");
    }
}
