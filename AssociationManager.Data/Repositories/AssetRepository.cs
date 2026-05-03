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

    public async Task<IEnumerable<Asset>> GetHierarchyAsync(int tenantId, int associationId, int? parentId = null, int? userId = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Asset>(
            "assoc.sp_Assets_GetHierarchy", 
            new { TenantId = tenantId, AssociationId = associationId, ParentId = parentId, UserId = userId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Asset>> GetAllFlatAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Asset>(
            "assoc.sp_Assets_GetAllFlat", 
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

    public async Task<int> BulkCreateAsync(IEnumerable<Asset> assets)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var dt = new DataTable();
        dt.Columns.Add("ParentId", typeof(int));
        dt.Columns.Add("TenantId", typeof(int));
        dt.Columns.Add("AssociationId", typeof(int));
        dt.Columns.Add("Name", typeof(string));
        dt.Columns.Add("Description", typeof(string));
        dt.Columns.Add("AssetType", typeof(int));
        dt.Columns.Add("MetadataJson", typeof(string));
        dt.Columns.Add("CreatedDate", typeof(System.DateTime));
        dt.Columns.Add("CreatedBy", typeof(int));
        dt.Columns.Add("IsActive", typeof(bool));

        foreach (var asset in assets)
        {
            dt.Rows.Add(
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
            );
        }

        return await connection.ExecuteAsync(
            "assoc.sp_Assets_BulkCreate",
            new { Assets = dt.AsTableValuedParameter("assoc.AssetTableType") },
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
            "assoc.sp_Assets_GetAssignedTariffs", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }
}
