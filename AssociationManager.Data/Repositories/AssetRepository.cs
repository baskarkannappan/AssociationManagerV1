using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AssetRepository : IAssetRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public AssetRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<Asset?> GetByIdAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Asset>(
            "SELECT * FROM Assets WHERE AssetId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = tenantId });
    }

    public async Task<IEnumerable<Asset>> GetByParentIdAsync(int? parentId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "SELECT * FROM Assets WHERE TenantId = @TenantId AND " + 
                     (parentId.HasValue ? "ParentId = @ParentId" : "ParentId IS NULL");
        return await connection.QueryAsync<Asset>(sql, new { TenantId = tenantId, ParentId = parentId });
    }

    public async Task<IEnumerable<Asset>> GetHierarchyAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        // Fetch all assets for the tenant and build the hierarchy in memory (best for small/medium sets)
        return await connection.QueryAsync<Asset>(
            "SELECT * FROM Assets WHERE TenantId = @TenantId AND IsActive = 1 ORDER BY ParentId, AssetType", 
            new { TenantId = tenantId });
    }

    public async Task<int> CreateAsync(Asset asset)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            INSERT INTO Assets (ParentId, TenantId, Name, Description, AssetType, MetadataJson, CreatedDate, CreatedBy, IsActive)
            OUTPUT INSERTED.AssetId
            VALUES (@ParentId, @TenantId, @Name, @Description, @AssetType, @MetadataJson, @CreatedDate, @CreatedBy, @IsActive)";
        return await connection.ExecuteScalarAsync<int>(sql, asset);
    }

    public async Task<bool> UpdateAsync(Asset asset)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            UPDATE Assets 
            SET ParentId = @ParentId, 
                Name = @Name, 
                Description = @Description, 
                AssetType = @AssetType, 
                MetadataJson = @MetadataJson, 
                IsActive = @IsActive 
            WHERE AssetId = @AssetId AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, asset);
        return affectedRows > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        // Soft delete for safety
        string sql = "UPDATE Assets SET IsActive = 0 WHERE AssetId = @Id AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, TenantId = tenantId });
        return affectedRows > 0;
    }
}
