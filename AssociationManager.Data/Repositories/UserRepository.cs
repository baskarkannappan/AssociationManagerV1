using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
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
            "sp_Users_GetById", 
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<User?> GetByGoogleIdAsync(string googleId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "sp_Users_GetByGoogleId", 
            new { GoogleId = googleId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "sp_Users_GetByEmail", 
            new { Email = email },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<User>> GetByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<User>(
            "sp_Users_GetByTenantId", 
            new { TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "sp_Users_Create", 
            user,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_Users_Update", 
            user,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> IsUserInTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "sp_UserAssociations_CheckExists", 
            new { UserId = userId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> AddUserToTenantAsync(int userId, int tenantId, string role)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_UserAssociations_Upsert", 
            new { UserId = userId, TenantId = tenantId, Role = role },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<string?> GetRoleInTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<string>(
            "sp_UserAssociations_GetRole", 
            new { UserId = userId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> RemoveUserFromTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_UserAssociations_Delete", 
            new { UserId = userId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
