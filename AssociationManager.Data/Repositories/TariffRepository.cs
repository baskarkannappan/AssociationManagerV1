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

    public async Task<IEnumerable<TariffGroup>> GetGroupsByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<TariffGroup>(
            "sp_TariffGroups_GetByTenantId", 
            new { tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateGroupAsync(TariffGroup group)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "sp_TariffGroups_Create", 
            group,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateGroupAsync(TariffGroup group)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_TariffGroups_Update", 
            group,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteGroupAsync(int groupId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_TariffGroups_Delete", 
            new { groupId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<TariffLayer>> GetLayersByGroupIdAsync(int groupId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<TariffLayer>(
            "sp_TariffLayers_GetByGroupId", 
            new { groupId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateLayerAsync(TariffLayer layer)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "sp_TariffLayers_Create", 
            layer,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateLayerAsync(TariffLayer layer)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_TariffLayers_Update", 
            layer,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteLayerAsync(int layerId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_TariffLayers_Delete", 
            new { layerId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<AssetTariff>> GetTariffsByAssetIdAsync(int assetId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AssetTariff>(
            "sp_AssetTariffs_GetByAssetId", 
            new { assetId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpsertAssetTariffAsync(AssetTariff assetTariff)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_AssetTariffs_Upsert", 
            assetTariff,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> RemoveAssetTariffAsync(int assetId, int layerId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "sp_AssetTariffs_Delete", 
            new { assetId, layerId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<AssetTariff>> GetActiveTariffsByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<AssetTariff>(
            "sp_AssetTariffs_GetActiveByTenantId", 
            new { tenantId },
            commandType: CommandType.StoredProcedure);
    }
}
