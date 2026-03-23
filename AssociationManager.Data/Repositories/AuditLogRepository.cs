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
        if (log.AssociationId == 0) log.AssociationId = _tenantContext.AssociationId;
        
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_AuditLogs_Create", 
            new 
            { 
                log.TenantId, 
                log.AssociationId, 
                log.UserId, 
                log.Action, 
                log.Entity, 
                log.EntityId, 
                log.IpAddress, 
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
}
