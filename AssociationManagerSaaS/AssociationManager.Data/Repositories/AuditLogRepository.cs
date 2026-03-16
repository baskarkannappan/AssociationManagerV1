using System.Collections.Generic;
using System.Threading.Tasks;
using Dapper;
using AssociationManager.Shared.Models;
using AssociationManager.Data.Interfaces;

namespace AssociationManager.Data.Repositories
{
    public class AuditLogRepository : IAuditLogRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public AuditLogRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<int> CreateAsync(AuditLog log)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "INSERT INTO AuditLogs (TenantId, UserId, Action, EntityName, EntityId, Changes) VALUES (@TenantId, @UserId, @Action, @EntityName, @EntityId, @Changes); SELECT CAST(SCOPE_IDENTITY() as int)";
            return await connection.ExecuteScalarAsync<int>(sql, log);
        }

        public async Task<IEnumerable<AuditLog>> GetByTenantIdAsync(int tenantId)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryAsync<AuditLog>("SELECT * FROM AuditLogs WHERE TenantId = @TenantId ORDER BY CreatedAt DESC", new { TenantId = tenantId });
        }
    }
}
