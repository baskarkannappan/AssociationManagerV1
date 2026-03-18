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
        string sql = @"
            SELECT u.*, ua.Role 
            FROM Users u
            JOIN UserAssociations ua ON u.UserId = ua.UserId
            WHERE ua.TenantId = @TenantId";
        return await connection.QueryAsync<User>(sql, new { TenantId = tenantId });
    }

    public async Task<int> CreateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) " +
                     "OUTPUT INSERTED.UserId " +
                     "VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive)";
        return await connection.ExecuteScalarAsync<int>(sql, user);
    }

    public async Task<bool> UpdateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE Users SET Name = @Name, PictureUrl = @PictureUrl, Role = @Role, LastLoginDate = @LastLoginDate, IsActive = @IsActive WHERE UserId = @UserId";
        int affectedRows = await connection.ExecuteAsync(sql, user);
        return affectedRows > 0;
    }

    public async Task<bool> IsUserInTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var result = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(1) FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId",
            new { UserId = userId, TenantId = tenantId });
        return result > 0;
    }

    public async Task<bool> AddUserToTenantAsync(int userId, int tenantId, string role)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            IF EXISTS (SELECT 1 FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId)
                UPDATE UserAssociations SET Role = @Role WHERE UserId = @UserId AND TenantId = @TenantId
            ELSE
                INSERT INTO UserAssociations (UserId, TenantId, Role) VALUES (@UserId, @TenantId, @Role)";
        int affectedRows = await connection.ExecuteAsync(sql, new { UserId = userId, TenantId = tenantId, Role = role });
        return affectedRows > 0;
    }

    public async Task<string?> GetRoleInTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<string>(
            "SELECT Role FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId",
            new { UserId = userId, TenantId = tenantId });
    }

    public async Task<bool> RemoveUserFromTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "DELETE FROM UserAssociations WHERE UserId = @UserId AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, new { UserId = userId, TenantId = tenantId });
        return affectedRows > 0;
    }
}
