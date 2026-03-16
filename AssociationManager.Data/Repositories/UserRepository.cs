using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class UserRepository : IUserRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public UserRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<User?> GetByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "SELECT * FROM Users WHERE UserId = @Id", new { Id = id });
    }

    public async Task<User?> GetByGoogleIdAsync(string googleId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "SELECT * FROM Users WHERE GoogleId = @GoogleId", new { GoogleId = googleId });
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "SELECT * FROM Users WHERE Email = @Email", new { Email = email });
    }

    public async Task<IEnumerable<User>> GetByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<User>(
            "SELECT * FROM Users WHERE TenantId = @TenantId", new { TenantId = tenantId });
    }

    public async Task<int> CreateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO Users (TenantId, GoogleId, Email, Name, PictureUrl, CreatedDate, LastLoginDate, IsActive) " +
                     "OUTPUT INSERTED.UserId " +
                     "VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @CreatedDate, @LastLoginDate, @IsActive)";
        return await connection.ExecuteScalarAsync<int>(sql, user);
    }

    public async Task<bool> UpdateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE Users SET Name = @Name, PictureUrl = @PictureUrl, LastLoginDate = @LastLoginDate, IsActive = @IsActive WHERE UserId = @UserId";
        int affectedRows = await connection.ExecuteAsync(sql, user);
        return affectedRows > 0;
    }
}
