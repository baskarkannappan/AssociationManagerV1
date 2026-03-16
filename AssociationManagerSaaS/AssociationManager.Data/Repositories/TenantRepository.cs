using System.Collections.Generic;
using System.Threading.Tasks;
using Dapper;
using AssociationManager.Shared.Models;
using AssociationManager.Data.Interfaces;

namespace AssociationManager.Data.Repositories
{
    public class TenantRepository : ITenantRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public TenantRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<IEnumerable<Tenant>> GetAllAsync()
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryAsync<Tenant>("SELECT * FROM Tenants WHERE IsActive = 1");
        }

        public async Task<Tenant?> GetByIdAsync(int id)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<Tenant>("SELECT * FROM Tenants WHERE Id = @Id", new { Id = id });
        }

        public async Task<Tenant?> GetByIdentifierAsync(string identifier)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<Tenant>("SELECT * FROM Tenants WHERE Identifier = @Identifier", new { Identifier = identifier });
        }

        public async Task<int> CreateAsync(Tenant tenant)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "INSERT INTO Tenants (Name, Identifier, IsActive) VALUES (@Name, @Identifier, @IsActive); SELECT CAST(SCOPE_IDENTITY() as int)";
            return await connection.ExecuteScalarAsync<int>(sql, tenant);
        }

        public async Task UpdateAsync(Tenant tenant)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "UPDATE Tenants SET Name = @Name, Identifier = @Identifier, IsActive = @IsActive, UpdatedAt = GETUTCDATE() WHERE Id = @Id";
            await connection.ExecuteAsync(sql, tenant);
        }

        public async Task<IEnumerable<Tenant>> GetByUserIdAsync(int userId)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = @"SELECT t.* FROM Tenants t 
                        INNER JOIN UserTenants ut ON t.Id = ut.TenantId 
                        WHERE ut.UserId = @UserId AND t.IsActive = 1";
            return await connection.QueryAsync<Tenant>(sql, new { UserId = userId });
        }
    }
}
