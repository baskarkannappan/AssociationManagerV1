using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AuditLogRepository : IAuditLogRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public AuditLogRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<int> CreateAsync(AuditLog log)
    {
        if (log.TenantId == 0) log.TenantId = _tenantContext.TenantId;
        log.AssociationId ??= _tenantContext.AssociationId != 0 ? _tenantContext.AssociationId : null;
        if (log.AssociationId == 0) log.AssociationId = null;
        
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_AuditLogs_Create", 
            new 
            { 
                log.TenantId, 
                log.AssociationId, 
                log.UserId, 
                log.AssetId,
                log.Action, 
                log.Entity, 
                log.EntityId, 
                log.IpAddress, 
                log.CorrelationId,
                log.Timestamp 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<AuditLog>> GetByTenantIdAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AuditLog>(
            "corp.sp_AuditLogs_GetByTenantId", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<AuditLog>> GetRecentByTenantIdAsync(int tenantId, int associationId, int count)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AuditLog>(
            "corp.sp_AuditLogs_GetRecent", 
            new { TenantId = tenantId, AssociationId = associationId, Count = count },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<AuditLog>> GetByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AuditLog>(
            "assoc.sp_AuditLogs_GetByAssetId", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> CreateBulkAsync(int tenantId, int associationId, int userId, IEnumerable<AuditLog> logs)
    {
        var dt = new DataTable();
        dt.Columns.Add("AssetId", typeof(int));
        dt.Columns.Add("Action", typeof(string));
        dt.Columns.Add("Entity", typeof(string));
        dt.Columns.Add("EntityId", typeof(int));
        dt.Columns.Add("Timestamp", typeof(DateTime));

        foreach (var log in logs)
        {
            dt.Rows.Add(log.AssetId, log.Action, log.Entity, log.EntityId, log.Timestamp);
        }

        using var connection = _dbConnectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "assoc.sp_AuditLogs_CreateBulk",
            new
            {
                TenantId = tenantId,
                AssociationId = associationId,
                UserId = userId,
                Logs = dt.AsTableValuedParameter("assoc.typ_AuditLogBatch")
            },
            commandType: CommandType.StoredProcedure);

        return true;
    }
}
