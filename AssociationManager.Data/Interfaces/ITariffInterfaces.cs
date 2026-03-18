using System;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface ITariffRepository
{
    // Groups
    Task<IEnumerable<TariffGroup>> GetGroupsByTenantIdAsync(int tenantId);
    Task<int> CreateGroupAsync(TariffGroup group);
    Task<bool> UpdateGroupAsync(TariffGroup group);
    Task<bool> DeleteGroupAsync(int groupId);

    // Layers
    Task<IEnumerable<TariffLayer>> GetLayersByGroupIdAsync(int groupId);
    Task<int> CreateLayerAsync(TariffLayer layer);
    Task<bool> UpdateLayerAsync(TariffLayer layer);
    Task<bool> DeleteLayerAsync(int layerId);

    // Asset Attachments
    Task<IEnumerable<AssetTariff>> GetTariffsByAssetIdAsync(int assetId);
    Task<bool> UpsertAssetTariffAsync(AssetTariff assetTariff);
    Task<bool> RemoveAssetTariffAsync(int assetId, int layerId);
    Task<IEnumerable<AssetTariff>> GetActiveTariffsByTenantIdAsync(int tenantId);
}

public interface ITransactionRepository
{
    Task<long> CreateTransactionAsync(Transaction transaction);
    Task<IEnumerable<Transaction>> GetByAssetIdAsync(int assetId, int tenantId, int associationId);
    Task<IEnumerable<Transaction>> GetByTenantIdAsync(int tenantId, int associationId, DateTime? startDate = null, DateTime? endDate = null);
    Task<decimal> GetBalanceByAssetIdAsync(int assetId, int tenantId, int associationId);
}
