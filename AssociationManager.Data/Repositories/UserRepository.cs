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
    private readonly string _schema;
    private readonly string _mappingIdColumn;

    public UserRepository(DbConnectionFactory dbConnectionFactory, string schema = "corp")
    {
        _dbConnectionFactory = dbConnectionFactory;
        _schema = schema;
        _mappingIdColumn = schema == "corp" ? "TenantId" : "AssociationId";
    }

    public async Task<User?> GetByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            $"{_schema}.sp_Users_GetById", 
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<User?> GetByGoogleIdAsync(string googleId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            $"{_schema}.sp_Users_GetByGoogleId", 
            new { GoogleId = googleId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            $"{_schema}.sp_Users_GetByEmail", 
            new { Email = email },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<User?> GetByEmailGlobalAsync(string email)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "corp.sp_Users_GetByEmail", 
            new { Email = email },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<User>> GetByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var spName = _schema == "corp" ? "corp.sp_Users_GetByTenantId" : "assoc.sp_Users_GetByAssociationId";
        var paramName = _mappingIdColumn;
        
        var dynamicParams = new DynamicParameters();
        dynamicParams.Add(paramName, tenantId);

        return await connection.QueryAsync<User>(
            spName, 
            dynamicParams,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            $"{_schema}.sp_Users_Create", 
            new 
            { 
                user.TenantId, 
                user.GoogleId, 
                user.Email, 
                user.Name, 
                user.PictureUrl, 
                user.Role, 
                user.CreatedDate, 
                user.LastLoginDate, 
                user.IsActive 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            $"{_schema}.sp_Users_Update", 
            new 
            { 
                user.UserId,
                user.Name, 
                user.PictureUrl, 
                user.Role, 
                user.LastLoginDate, 
                user.IsActive 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> IsUserInTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var dynamicParams = new DynamicParameters();
        dynamicParams.Add("UserId", userId);
        dynamicParams.Add(_mappingIdColumn, tenantId);

        return await connection.ExecuteScalarAsync<int>(
            $"{_schema}.sp_UserAssociations_CheckExists", 
            dynamicParams,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> AddUserToTenantAsync(int userId, int tenantId, string role)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var dynamicParams = new DynamicParameters();
        dynamicParams.Add("UserId", userId);
        dynamicParams.Add(_mappingIdColumn, tenantId);
        dynamicParams.Add("Role", role);

        return await connection.ExecuteAsync(
            $"{_schema}.sp_UserAssociations_Upsert", 
            dynamicParams,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<string?> GetRoleInTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var dynamicParams = new DynamicParameters();
        dynamicParams.Add("UserId", userId);
        dynamicParams.Add(_mappingIdColumn, tenantId);

        return await connection.QueryFirstOrDefaultAsync<string>(
            $"{_schema}.sp_UserAssociations_GetRole", 
            dynamicParams,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> RemoveUserFromTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var dynamicParams = new DynamicParameters();
        dynamicParams.Add("UserId", userId);
        dynamicParams.Add(_mappingIdColumn, tenantId);

        return await connection.ExecuteAsync(
            $"{_schema}.sp_UserAssociations_Delete", 
            dynamicParams,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> IsUserAuthorisedForAssociationAsync(int userId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        if (_schema == "assoc")
        {
            return await connection.ExecuteScalarAsync<int>(
                "assoc.sp_UserAssociations_IsAuthorised",
                new { UserId = userId, AssociationId = associationId },
                commandType: CommandType.StoredProcedure) > 0;
        }

        const string sql = @"
            SELECT COUNT(1) FROM (
                -- 1. High-level Admins see everything in their tenant
                SELECT a.AssociationId 
                FROM corp.Associations a
                INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
                WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'AssociationAdmin') AND a.AssociationId = @AssociationId

                UNION

                -- 2. Everyone else (Resident, UserManager, AssetManager, etc.) 
                -- only see associations they are directly linked to via Occupancy/Assets
                SELECT a.AssociationId
                FROM corp.Associations a
                INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
                INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
                INNER JOIN corp.Users u ON p.Email = u.Email
                WHERE u.UserId = @UserId AND a.AssociationId = @AssociationId
            ) AS AuthCheck";
        
        return await connection.ExecuteScalarAsync<int>(sql, new { UserId = userId, TenantId = tenantId, AssociationId = associationId }) > 0;
    }

    public async Task<IEnumerable<User>> GetByAssociationIdAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        
        if (_schema == "assoc")
        {
            return await connection.QueryAsync<User>(
                "assoc.sp_Users_GetByAssociationId",
                new { AssociationId = associationId },
                commandType: CommandType.StoredProcedure);
        }

        const string sql = @"
            SELECT DISTINCT u.*
            FROM corp.Users u
            LEFT JOIN assoc.Persons p ON u.Email = p.Email
            LEFT JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
            LEFT JOIN corp.UserAssociations ua ON u.TenantId = ua.TenantId
            WHERE 
                u.AssociationId = @AssociationId -- Active association
                OR o.AssociationId = @AssociationId -- Resident association
                OR (ua.Role IN ('SystemAdmin', 'AssociationAdmin') AND u.TenantId = (SELECT TenantId FROM corp.Associations WHERE AssociationId = @AssociationId))
            ORDER BY u.Name";
        
        return await connection.QueryAsync<User>(sql, new { AssociationId = associationId });
    }

    public async Task<IEnumerable<User>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<User>($"SELECT * FROM {_schema}.Users ORDER BY Name");
    }

    public async Task<bool> DeleteUserGlobalAsync(int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        await connection.ExecuteAsync($"DELETE FROM {_schema}.UserAssociations WHERE UserId = @UserId", new { UserId = userId });
        return await connection.ExecuteAsync($"DELETE FROM {_schema}.Users WHERE UserId = @UserId", new { UserId = userId }) > 0;
    }
}
