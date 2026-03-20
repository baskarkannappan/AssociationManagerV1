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
            "corp.sp_Users_GetById", 
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<User?> GetByGoogleIdAsync(string googleId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "corp.sp_Users_GetByGoogleId", 
            new { GoogleId = googleId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<User?> GetByEmailAsync(string email)
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
        return await connection.QueryAsync<User>(
            "corp.sp_Users_GetByTenantId", 
            new { TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(User user)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_Users_Create", 
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
            "corp.sp_Users_Update", 
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
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_UserAssociations_CheckExists", 
            new { UserId = userId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> AddUserToTenantAsync(int userId, int tenantId, string role)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_UserAssociations_Upsert", 
            new { UserId = userId, TenantId = tenantId, Role = role },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<string?> GetRoleInTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<string>(
            "corp.sp_UserAssociations_GetRole", 
            new { UserId = userId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> RemoveUserFromTenantAsync(int userId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_UserAssociations_Delete", 
            new { UserId = userId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> IsUserAuthorisedForAssociationAsync(int userId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
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
}
