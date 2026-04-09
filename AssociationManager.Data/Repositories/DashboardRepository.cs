using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class DashboardRepository : IDashboardRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public DashboardRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<int> GetTotalMembersAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Dashboard_GetTotalMembers", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> GetCommitteeCountAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Dashboard_GetCommitteeCount", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<decimal> GetRevenue30DAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<decimal>(
            "assoc.sp_Dashboard_GetRevenue30D", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<decimal> GetNetOutstandingAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<decimal>(
            "assoc.sp_Dashboard_GetNetOutstanding", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(decimal amount, int units)> GetHeldAdvanceMoneyAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var result = await connection.QueryFirstOrDefaultAsync(
            "assoc.sp_Dashboard_GetHeldAdvanceMoney", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
            
        if (result == null) return (0, 0);
        return ((decimal)result.TotalAdvanceCredits, (int)result.UnitsWithCredit);
    }
}
