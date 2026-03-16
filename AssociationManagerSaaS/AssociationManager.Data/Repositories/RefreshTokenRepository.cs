using System.Threading.Tasks;
using Dapper;
using AssociationManager.Shared.Models;
using AssociationManager.Data.Interfaces;

namespace AssociationManager.Data.Repositories
{
    public class RefreshTokenRepository : IRefreshTokenRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public RefreshTokenRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<int> CreateAsync(RefreshToken token)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "INSERT INTO RefreshTokens (UserId, Token, ExpiresAt, IsRevoked, ReplacedByToken) VALUES (@UserId, @Token, @ExpiresAt, @IsRevoked, @ReplacedByToken); SELECT CAST(SCOPE_IDENTITY() as int)";
            return await connection.ExecuteScalarAsync<int>(sql, token);
        }

        public async Task<RefreshToken?> GetByTokenAsync(string token)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<RefreshToken>("SELECT * FROM RefreshTokens WHERE Token = @Token", new { Token = token });
        }

        public async Task UpdateAsync(RefreshToken token)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "UPDATE RefreshTokens SET IsRevoked = @IsRevoked, ReplacedByToken = @ReplacedByToken, UpdatedAt = GETUTCDATE() WHERE Id = @Id";
            await connection.ExecuteAsync(sql, token);
        }

        public async Task RevokeAllForUserAsync(int userId)
        {
            using var connection = _connectionFactory.CreateConnection();
            await connection.ExecuteAsync("UPDATE RefreshTokens SET IsRevoked = 1, UpdatedAt = GETUTCDATE() WHERE UserId = @UserId AND IsRevoked = 0", new { UserId = userId });
        }
    }
}
