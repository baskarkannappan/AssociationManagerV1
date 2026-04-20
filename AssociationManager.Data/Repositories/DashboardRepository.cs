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

    public async Task<(decimal TotalRevenue, decimal NetOutstanding, decimal HeldAdvanceMoney, int UnitsWithCredit, int TotalMembers, int CommitteeCount, int PendingWorkOrders)> GetAdminSnapshotAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var row = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "assoc.sp_Dashboard_GetAdminSnapshot",
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);

        if (row == null) return (0m, 0m, 0m, 0, 0, 0, 0);

        return (
            (decimal)(row.TotalRevenue ?? 0m),
            (decimal)(row.NetOutstanding ?? 0m),
            (decimal)(row.HeldAdvanceMoney ?? 0m),
            (int)(row.UnitsWithCredit ?? 0),
            (int)(row.TotalMembers ?? 0),
            (int)(row.CommitteeMembers ?? 0),
            (int)(row.PendingWorkOrders ?? 0)
        );
    }
}
