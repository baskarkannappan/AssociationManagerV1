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
    public string Schema => _schema;
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

        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_Users_IsAuthorisedForAssociation",
            new { UserId = userId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
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

        return await connection.QueryAsync<User>(
            "corp.sp_Users_GetByAssociationId_Complex",
            new { AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<PagedResult<User>> GetPagedAsync(UserSearchCriteria criteria)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AssociationId", criteria.AssociationId);
        parameters.Add("@TenantId", criteria.AssociationId == null ? (int?)null : (int?)null); // Placeholder if needed
        parameters.Add("@SearchTerm", criteria.SearchTerm);
        parameters.Add("@Role", criteria.Role);
        parameters.Add("@PageNumber", criteria.PageNumber);
        parameters.Add("@PageSize", criteria.PageSize);
        parameters.Add("@SortColumn", criteria.SortColumn);
        parameters.Add("@SortDirection", criteria.SortDirection);

        var result = new PagedResult<User>
        {
            PageNumber = criteria.PageNumber,
            PageSize = criteria.PageSize
        };

        var items = await connection.QueryAsync<dynamic>(
            "assoc.sp_Users_GetPaged", 
            parameters, 
            commandType: CommandType.StoredProcedure);

        var users = new List<User>();
        foreach (var row in items)
        {
            if (result.TotalCount == 0)
            {
                result.TotalCount = row.TotalCount;
            }

            users.Add(new User
            {
                UserId = row.UserId,
                Name = row.Name,
                Email = row.Email,
                PictureUrl = row.PictureUrl,
                IsActive = row.IsActive,
                CreatedDate = row.CreatedDate,
                Role = row.Role, // This is the role from UserTenantMapping
                Balance = row.Balance ?? 0m
            });
        }
        
        result.Items = users;
        result.FilteredCount = result.TotalCount;

        return result;
    }


    public async Task<IEnumerable<User>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<User>(
            $"{_schema}.sp_Users_List",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteUserGlobalAsync(int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            $"{_schema}.sp_Users_DeleteGlobal",
            new { UserId = userId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
