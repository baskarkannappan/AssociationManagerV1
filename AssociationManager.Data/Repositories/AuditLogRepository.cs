using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
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
        log.TenantId = _tenantContext.TenantId;
        log.AssociationId = _tenantContext.AssociationId;
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO AuditLogs (TenantId, AssociationId, UserId, Action, Entity, EntityId, IpAddress, Timestamp) " +
                     "OUTPUT INSERTED.AuditLogId " +
                     "VALUES (@TenantId, @AssociationId, @UserId, @Action, @Entity, @EntityId, @IpAddress, @Timestamp)";
        return await connection.ExecuteScalarAsync<int>(sql, log);
    }

    public async Task<IEnumerable<AuditLog>> GetByTenantIdAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AuditLog>(
            "SELECT * FROM AuditLogs WHERE TenantId = @TenantId AND AssociationId = @AssociationId ORDER BY Timestamp DESC", 
            new { TenantId = tenantId, AssociationId = associationId });
    }
}
