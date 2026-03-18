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
        const string sql = "SELECT * FROM TariffGroups WHERE TenantId = @tenantId";
        return await connection.QueryAsync<TariffGroup>(sql, new { tenantId });
    }

    public async Task<int> CreateGroupAsync(TariffGroup group)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = @"INSERT INTO TariffGroups (TenantId, Name, Description) 
                           VALUES (@TenantId, @Name, @Description);
                           SELECT CAST(SCOPE_IDENTITY() as int)";
        return await connection.ExecuteScalarAsync<int>(sql, group);
    }

    public async Task<bool> UpdateGroupAsync(TariffGroup group)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = "UPDATE TariffGroups SET Name = @Name, Description = @Description WHERE TariffGroupId = @TariffGroupId";
        return await connection.ExecuteAsync(sql, group) > 0;
    }

    public async Task<bool> DeleteGroupAsync(int groupId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = "DELETE FROM TariffGroups WHERE TariffGroupId = @groupId";
        return await connection.ExecuteAsync(sql, new { groupId }) > 0;
    }

    public async Task<IEnumerable<TariffLayer>> GetLayersByGroupIdAsync(int groupId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = "SELECT * FROM TariffLayers WHERE TariffGroupId = @groupId";
        return await connection.QueryAsync<TariffLayer>(sql, new { groupId });
    }

    public async Task<int> CreateLayerAsync(TariffLayer layer)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = @"INSERT INTO TariffLayers (TariffGroupId, TenantId, Name, BaseRate, Frequency, CalculationType, AccountingCategory) 
                           VALUES (@TariffGroupId, @TenantId, @Name, @BaseRate, @Frequency, @CalculationType, @AccountingCategory);
                           SELECT CAST(SCOPE_IDENTITY() as int)";
        return await connection.ExecuteScalarAsync<int>(sql, layer);
    }

    public async Task<bool> UpdateLayerAsync(TariffLayer layer)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = @"UPDATE TariffLayers SET Name = @Name, BaseRate = @BaseRate, Frequency = @Frequency, 
                             CalculationType = @CalculationType, AccountingCategory = @AccountingCategory 
                             WHERE TariffLayerId = @TariffLayerId";
        return await connection.ExecuteAsync(sql, layer) > 0;
    }

    public async Task<bool> DeleteLayerAsync(int layerId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = "DELETE FROM TariffLayers WHERE TariffLayerId = @layerId";
        return await connection.ExecuteAsync(sql, new { layerId }) > 0;
    }

    public async Task<IEnumerable<AssetTariff>> GetTariffsByAssetIdAsync(int assetId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = "SELECT * FROM AssetTariffs WHERE AssetId = @assetId";
        return await connection.QueryAsync<AssetTariff>(sql, new { assetId });
    }

    public async Task<bool> UpsertAssetTariffAsync(AssetTariff assetTariff)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = @"IF EXISTS (SELECT 1 FROM AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId)
                             UPDATE AssetTariffs SET CustomAmount = @CustomAmount, IsActive = @IsActive 
                             WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId
                             ELSE
                             INSERT INTO AssetTariffs (AssetId, TariffLayerId, CustomAmount, IsActive) 
                             VALUES (@AssetId, @TariffLayerId, @CustomAmount, @IsActive)";
        return await connection.ExecuteAsync(sql, assetTariff) > 0;
    }

    public async Task<bool> RemoveAssetTariffAsync(int assetId, int layerId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = "DELETE FROM AssetTariffs WHERE AssetId = @assetId AND TariffLayerId = @layerId";
        return await connection.ExecuteAsync(sql, new { assetId, layerId }) > 0;
    }

    public async Task<IEnumerable<AssetTariff>> GetActiveTariffsByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = @"SELECT at.* FROM AssetTariffs at 
                             JOIN TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId 
                             WHERE tl.TenantId = @tenantId AND at.IsActive = 1";
        return await connection.QueryAsync<AssetTariff>(sql, new { tenantId });
    }
}
