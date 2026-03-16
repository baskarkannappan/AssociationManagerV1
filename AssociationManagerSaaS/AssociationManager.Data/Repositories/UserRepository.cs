using System.Threading.Tasks;
using Dapper;
using AssociationManager.Shared.Models;
using AssociationManager.Data.Interfaces;

namespace AssociationManager.Data.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public UserRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<User?> GetByIdAsync(int id)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<User>("SELECT * FROM Users WHERE Id = @Id", new { Id = id });
        }

        public async Task<User?> GetByEmailAsync(string email)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<User>("SELECT * FROM Users WHERE Email = @Email", new { Email = email });
        }

        public async Task<int> CreateAsync(User user)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "INSERT INTO Users (Email, FullName, GoogleId, IsActive) VALUES (@Email, @FullName, @GoogleId, @IsActive); SELECT CAST(SCOPE_IDENTITY() as int)";
            return await connection.ExecuteScalarAsync<int>(sql, user);
        }

        public async Task UpdateAsync(User user)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "UPDATE Users SET FullName = @FullName, GoogleId = @GoogleId, IsActive = @IsActive, UpdatedAt = GETUTCDATE() WHERE Id = @Id";
            await connection.ExecuteAsync(sql, user);
        }

        public async Task AddToTenantAsync(int userId, int tenantId)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "IF NOT EXISTS (SELECT 1 FROM UserTenants WHERE UserId = @UserId AND TenantId = @TenantId) INSERT INTO UserTenants (UserId, TenantId) VALUES (@UserId, @TenantId)";
            await connection.ExecuteAsync(sql, new { UserId = userId, TenantId = tenantId });
        }
    }
}
