using System.Collections.Generic;
using System.Threading.Tasks;
using Dapper;
using AssociationManager.Shared.Models;
using AssociationManager.Data.Interfaces;

namespace AssociationManager.Data.Repositories
{
    public class AssociationRepository : IAssociationRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public AssociationRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<IEnumerable<Association>> GetByTenantIdAsync(int tenantId)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryAsync<Association>("SELECT * FROM Associations WHERE TenantId = @TenantId", new { TenantId = tenantId });
        }

        public async Task<Association?> GetByIdAsync(int id, int tenantId)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<Association>("SELECT * FROM Associations WHERE Id = @Id AND TenantId = @TenantId", new { Id = id, TenantId = tenantId });
        }

        public async Task<int> CreateAsync(Association association)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "INSERT INTO Associations (TenantId, Name, Description) VALUES (@TenantId, @Name, @Description); SELECT CAST(SCOPE_IDENTITY() as int)";
            return await connection.ExecuteScalarAsync<int>(sql, association);
        }

        public async Task UpdateAsync(Association association)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "UPDATE Associations SET Name = @Name, Description = @Description, UpdatedAt = GETUTCDATE() WHERE Id = @Id AND TenantId = @TenantId";
            await connection.ExecuteAsync(sql, association);
        }

        public async Task DeleteAsync(int id, int tenantId)
        {
            using var connection = _connectionFactory.CreateConnection();
            await connection.ExecuteAsync("DELETE FROM Associations WHERE Id = @Id AND TenantId = @TenantId", new { Id = id, TenantId = tenantId });
        }
    }
}
