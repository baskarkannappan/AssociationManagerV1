using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
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
            "assoc.sp_Assets_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Asset>> GetByParentIdAsync(int? parentId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Asset>(
            "assoc.sp_Assets_GetByParentId", 
            new { ParentId = parentId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Asset>> GetHierarchyAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        // Fetch all assets for the association and build the hierarchy in memory
        return await connection.QueryAsync<Asset>(
            "assoc.sp_Assets_GetHierarchy", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Asset asset)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Assets_Create", 
            new 
            { 
                asset.ParentId, 
                asset.TenantId, 
                asset.AssociationId, 
                asset.Name, 
                asset.Description, 
                asset.AssetType, 
                asset.MetadataJson, 
                asset.CreatedDate, 
                asset.CreatedBy, 
                asset.IsActive 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Asset asset)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Assets_Update", 
            new 
            { 
                asset.AssetId,
                asset.TenantId, 
                asset.AssociationId, 
                asset.ParentId, 
                asset.Name, 
                asset.Description, 
                asset.AssetType, 
                asset.MetadataJson, 
                asset.IsActive 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        // Soft delete for safety
        return await connection.ExecuteAsync(
            "assoc.sp_Assets_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<int> CountAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Assets_Count",
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<dynamic>> GetAssignedTariffsAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<dynamic>(
            "SELECT t.TariffLayerId, t.Name as TariffName, t.AccountingCategory as Category, ISNULL(at.CustomAmount, t.BaseRate) as EffectiveAmount, t.BaseRate as BaseAmount, at.IsActive, at.IsRecurring " +
            "FROM assoc.AssetTariffs at " +
            "JOIN assoc.TariffLayers t ON at.TariffLayerId = t.TariffLayerId " +
            "WHERE at.AssetId = @AssetId AND t.TenantId = @TenantId AND t.AssociationId = @AssociationId",
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId });
    }
}
