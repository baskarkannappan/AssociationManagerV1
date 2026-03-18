using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AssetRepository : IAssetRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public AssetRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Asset?> GetByIdAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Asset>(
            "SELECT * FROM Assets WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId });
    }

    public async Task<IEnumerable<Asset>> GetByParentIdAsync(int? parentId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "SELECT * FROM Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND " + 
                     (parentId.HasValue ? "ParentId = @ParentId" : "ParentId IS NULL");
        return await connection.QueryAsync<Asset>(sql, new { TenantId = tenantId, AssociationId = associationId, ParentId = parentId });
    }

    public async Task<IEnumerable<Asset>> GetHierarchyAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        // Fetch all assets for the association and build the hierarchy in memory
        return await connection.QueryAsync<Asset>(
            "SELECT * FROM Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND IsActive = 1 ORDER BY ParentId, AssetType", 
            new { TenantId = tenantId, AssociationId = associationId });
    }

    public async Task<int> CreateAsync(Asset asset)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            INSERT INTO Assets (ParentId, TenantId, AssociationId, Name, Description, AssetType, MetadataJson, CreatedDate, CreatedBy, IsActive)
            OUTPUT INSERTED.AssetId
            VALUES (@ParentId, @TenantId, @AssociationId, @Name, @Description, @AssetType, @MetadataJson, @CreatedDate, @CreatedBy, @IsActive)";
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
            WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId";
        int affectedRows = await connection.ExecuteAsync(sql, asset);
        return affectedRows > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        // Soft delete for safety
        string sql = "UPDATE Assets SET IsActive = 0 WHERE AssetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, TenantId = tenantId, AssociationId = associationId });
        return affectedRows > 0;
    }
}
