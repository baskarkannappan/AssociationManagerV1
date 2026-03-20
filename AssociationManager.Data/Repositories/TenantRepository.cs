using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class TenantRepository : ITenantRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public TenantRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<Tenant?> GetByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Tenant>(
            "corp.sp_Tenants_GetById", 
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Tenant>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Tenant>(
            "corp.sp_Tenants_GetAll", 
            null,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Tenant tenant)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_Tenants_Create", 
            new { tenant.Name, tenant.CreatedDate, tenant.IsActive },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Tenant tenant)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Tenants_Update", 
            new { tenant.TenantId, tenant.Name, tenant.IsActive },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
