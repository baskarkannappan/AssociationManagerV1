using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AuditLogRepository : IAuditLogRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public AuditLogRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<int> CreateAsync(AuditLog log)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO AuditLogs (TenantId, UserId, Action, Entity, EntityId, IpAddress, Timestamp) " +
                     "OUTPUT INSERTED.AuditLogId " +
                     "VALUES (@TenantId, @UserId, @Action, @Entity, @EntityId, @IpAddress, @Timestamp)";
        return await connection.ExecuteScalarAsync<int>(sql, log);
    }

    public async Task<IEnumerable<AuditLog>> GetByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AuditLog>(
            "SELECT * FROM AuditLogs WHERE TenantId = @TenantId ORDER BY Timestamp DESC", 
            new { TenantId = tenantId });
    }
}
