using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class BroadcastRepository : IBroadcastRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public BroadcastRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Broadcast?> GetByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Broadcast>(
            @"SELECT b.*, u.Name as AuthorName 
              FROM Broadcasts b 
              LEFT JOIN Users u ON b.CreatedBy = u.UserId
              WHERE b.BroadcastId = @Id AND b.TenantId = @TenantId", 
            new { Id = id, TenantId = _tenantContext.TenantId });
    }

    public async Task<IEnumerable<Broadcast>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Broadcast>(
            @"SELECT b.*, u.Name as AuthorName 
              FROM Broadcasts b 
              LEFT JOIN Users u ON b.CreatedBy = u.UserId
              WHERE b.TenantId = @TenantId 
              ORDER BY b.IsPinned DESC, b.CreatedDate DESC", 
            new { TenantId = _tenantContext.TenantId });
    }

    public async Task<int> CreateAsync(Broadcast broadcast)
    {
        broadcast.TenantId = _tenantContext.TenantId;
        broadcast.CreatedBy = _tenantContext.UserId;
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"INSERT INTO Broadcasts (TenantId, Title, Content, Category, CreatedDate, CreatedBy, IsPinned, ExpiresDate) 
                       OUTPUT INSERTED.BroadcastId 
                       VALUES (@TenantId, @Title, @Content, @Category, @CreatedDate, @CreatedBy, @IsPinned, @ExpiresDate)";
        return await connection.ExecuteScalarAsync<int>(sql, broadcast);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "DELETE FROM Broadcasts WHERE BroadcastId = @Id AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, TenantId = _tenantContext.TenantId });
        return affectedRows > 0;
    }
}
