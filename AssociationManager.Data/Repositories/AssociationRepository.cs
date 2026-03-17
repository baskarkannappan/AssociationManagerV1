using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AssociationRepository : IAssociationRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public AssociationRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Association?> GetByIdAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Association>(
            "SELECT * FROM Associations WHERE AssociationId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = _tenantContext.TenantId });
    }

    public async Task<IEnumerable<Association>> GetAllByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            "SELECT * FROM Associations WHERE TenantId = @TenantId", 
            new { TenantId = _tenantContext.TenantId });
    }

    public async Task<int> CreateAsync(Association association)
    {
        association.TenantId = _tenantContext.TenantId;
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO Associations (TenantId, Name, Description, CreatedDate, CreatedBy) " +
                     "OUTPUT INSERTED.AssociationId " +
                     "VALUES (@TenantId, @Name, @Description, @CreatedDate, @CreatedBy)";
        return await connection.ExecuteScalarAsync<int>(sql, association);
    }

    public async Task<bool> UpdateAsync(Association association)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE Associations SET Name = @Name, Description = @Description WHERE AssociationId = @AssociationId AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, association);
        return affectedRows > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        int affectedRows = await connection.ExecuteAsync(
            "DELETE FROM Associations WHERE AssociationId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = _tenantContext.TenantId });
        return affectedRows > 0;
    }

    public async Task<IEnumerable<Association>> GetByUserIdAsync(int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            SELECT a.* 
            FROM Associations a
            INNER JOIN UserAssociations ua ON a.TenantId = ua.TenantId
            WHERE ua.UserId = @UserId";
        return await connection.QueryAsync<Association>(sql, new { UserId = userId });
    }
}
