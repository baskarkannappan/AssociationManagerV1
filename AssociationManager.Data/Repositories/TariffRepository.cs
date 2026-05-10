using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class TariffRepository : ITariffRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public TariffRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<IEnumerable<TariffGroup>> GetGroupsByTenantIdAsync(int tenantId, int? associationId = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var groups = await connection.QueryAsync<TariffGroup>(
            "assoc.sp_TariffGroups_GetByTenantId", 
            new { tenantId, associationId },
            commandType: CommandType.StoredProcedure);
        return groups.ToList();
    }

    public async Task<int> CreateGroupAsync(TariffGroup group)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_TariffGroups_Create", 
            new { group.TenantId, group.AssociationId, group.Name, group.Description },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateGroupAsync(TariffGroup group)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_TariffGroups_Update", 
            new { group.TariffGroupId, group.Name, group.Description },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteGroupAsync(int groupId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_TariffGroups_Delete", 
            new { groupId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<TariffLayer>> GetLayersByGroupIdAsync(int groupId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var layers = await connection.QueryAsync<TariffLayer>(
            "assoc.sp_TariffLayers_GetByGroupId", 
            new { groupId },
            commandType: CommandType.StoredProcedure);
        return layers.ToList();
    }

    public async Task<IEnumerable<TariffLayer>> GetLayersByAssociationIdAsync(int associationId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var layers = await connection.QueryAsync<TariffLayer>(
            "assoc.sp_TariffLayers_GetByAssociationId", 
            new { associationId, tenantId },
            commandType: CommandType.StoredProcedure);
        return layers.ToList();
    }

    public async Task<int> CreateLayerAsync(TariffLayer layer)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_TariffLayers_Create", 
            new 
            { 
                layer.TariffGroupId, 
                layer.TenantId, 
                layer.AssociationId,
                layer.Name, 
                layer.BaseRate, 
                layer.Frequency, 
                layer.CalculationType, 
                layer.AccountingCategory 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateLayerAsync(TariffLayer layer)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_TariffLayers_Update", 
            new 
            { 
                layer.TariffLayerId, 
                layer.Name, 
                layer.BaseRate, 
                layer.Frequency, 
                layer.CalculationType, 
                layer.AccountingCategory 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteLayerAsync(int layerId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_TariffLayers_Delete", 
            new { layerId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<AssetTariff>> GetTariffsByAssetIdAsync(int assetId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var tariffs = await connection.QueryAsync<AssetTariff>(
            "assoc.sp_AssetTariffs_GetByAssetId", 
            new { assetId },
            commandType: CommandType.StoredProcedure);
        return tariffs.ToList();
    }

    public async Task<bool> UpsertAssetTariffAsync(AssetTariff assetTariff)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_AssetTariffs_Upsert", 
            new { assetTariff.AssetId, assetTariff.TariffLayerId, assetTariff.CustomAmount, assetTariff.IsActive, assetTariff.IsRecurring },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> UpsertAssetTariffBulkAsync(IEnumerable<AssetTariff> tariffs)
    {
        if (tariffs == null || !tariffs.Any()) return true;

        var dt = new DataTable();
        dt.Columns.Add("AssetId", typeof(int));
        dt.Columns.Add("TariffLayerId", typeof(int));
        dt.Columns.Add("CustomAmount", typeof(decimal));
        dt.Columns.Add("IsActive", typeof(bool));
        dt.Columns.Add("IsRecurring", typeof(bool));

        foreach (var t in tariffs)
        {
            dt.Rows.Add(t.AssetId, t.TariffLayerId, t.CustomAmount, t.IsActive, t.IsRecurring);
        }

        using var connection = _dbConnectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "assoc.sp_AssetTariffs_UpsertBulk",
            new { TariffAssignments = dt.AsTableValuedParameter("assoc.typ_AssetTariffBatch") },
            commandType: CommandType.StoredProcedure);
        
        return true;
    }

    public async Task<IEnumerable<Asset>> GetAvailableAssetsForLayerAsync(int associationId, int layerId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var assets = await connection.QueryAsync<Asset>(
            "assoc.sp_Assets_GetAvailableForLayer",
            new { AssociationId = associationId, LayerId = layerId },
            commandType: CommandType.StoredProcedure);
        return assets.ToList();
    }

    public async Task<bool> DeactivateTariffsBulkAsync(int layerId, IEnumerable<int> assetIds)
    {
        if (assetIds == null || !assetIds.Any()) return true;

        using var connection = _dbConnectionFactory.CreateConnection();
        var dt = new DataTable();
        dt.Columns.Add("Id", typeof(int));
        foreach (var id in assetIds) dt.Rows.Add(id);

        return await connection.ExecuteAsync(
            "assoc.sp_AssetTariffs_DeactivateBulk", 
            new { layerId, AssetIds = dt.AsTableValuedParameter("assoc.IntegerList") },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> RemoveAssetTariffAsync(int assetId, int layerId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_AssetTariffs_Delete", 
            new { assetId, layerId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<AssetTariff>> GetActiveTariffsByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var tariffs = await connection.QueryAsync<AssetTariff>(
            "assoc.sp_AssetTariffs_GetActiveByTenantId", 
            new { tenantId },
            commandType: CommandType.StoredProcedure);
        return tariffs.ToList();
    }

    public async Task<IEnumerable<AssetTariff>> GetActiveTariffsByAssociationIdAsync(int associationId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var tariffs = await connection.QueryAsync<AssetTariff>(
            "assoc.sp_AssetTariffs_GetActiveByAssociationId", 
            new { associationId, tenantId },
            commandType: CommandType.StoredProcedure);
        return tariffs.ToList();
    }

    public async Task<IEnumerable<AssetTariff>> GetAssignmentsByLayerIdAsync(int layerId)
    {
        // TARGETED FETCH: Avoids pulling entire tenant data
        using var connection = _dbConnectionFactory.CreateConnection();
        var assignments = await connection.QueryAsync<AssetTariff>(
            "assoc.sp_AssetTariffs_GetAssignmentsByLayerId", 
            new { layerId },
            commandType: CommandType.StoredProcedure);
        return assignments.ToList();
    }
}
