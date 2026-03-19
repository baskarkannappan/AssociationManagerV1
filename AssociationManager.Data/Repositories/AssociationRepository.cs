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

    public AssociationRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Association?> GetByIdAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Association>(
            "sp_Associations_GetById", 
            new { Id = id, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Association>> GetAllByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            "sp_Associations_GetAllByTenantId", 
            new { TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Association association)
    {
        association.TenantId = _tenantContext.TenantId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "sp_Associations_Create", 
            association,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Association association)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_Associations_Update", 
            association,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_Associations_Delete", 
            new { Id = id, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<Association>> GetByUserIdAsync(int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            "sp_Associations_GetByUserId", 
            new { UserId = userId },
            commandType: CommandType.StoredProcedure);
    }
}
