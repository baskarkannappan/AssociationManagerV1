using System;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface ITariffRepository
{
    // Groups
    Task<IEnumerable<TariffGroup>> GetGroupsByTenantIdAsync(int tenantId, int? associationId = null);
    Task<int> CreateGroupAsync(TariffGroup group);
    Task<bool> UpdateGroupAsync(TariffGroup group);
    Task<bool> DeleteGroupAsync(int groupId);

    // Layers
    Task<IEnumerable<TariffLayer>> GetLayersByGroupIdAsync(int groupId);
    Task<IEnumerable<TariffLayer>> GetLayersByAssociationIdAsync(int associationId, int tenantId);
    Task<int> CreateLayerAsync(TariffLayer layer);
    Task<bool> UpdateLayerAsync(TariffLayer layer);
    Task<bool> DeleteLayerAsync(int layerId);

    // Asset Attachments
    Task<IEnumerable<AssetTariff>> GetTariffsByAssetIdAsync(int assetId);
    Task<bool> UpsertAssetTariffAsync(AssetTariff assetTariff);
    Task<bool> UpsertAssetTariffBulkAsync(IEnumerable<AssetTariff> tariffs);
    Task<IEnumerable<Asset>> GetAvailableAssetsForLayerAsync(int associationId, int layerId);
    Task<bool> DeactivateTariffsBulkAsync(int layerId, IEnumerable<int> assetIds);
    Task<bool> RemoveAssetTariffAsync(int assetId, int layerId);
    Task<IEnumerable<AssetTariff>> GetActiveTariffsByTenantIdAsync(int tenantId);
    Task<IEnumerable<AssetTariff>> GetAssignmentsByLayerIdAsync(int layerId);
}

public interface ITransactionRepository
{
    Task<long> CreateTransactionAsync(Transaction transaction);
    Task<IEnumerable<Transaction>> GetByAssetIdAsync(int? assetId, int tenantId, int associationId);
    Task<IEnumerable<Transaction>> GetByTenantIdAsync(int tenantId, int associationId, DateTime? startDate = null, DateTime? endDate = null);
    Task<IEnumerable<Transaction>> GetByInvoiceIdAsync(int invoiceId, int tenantId, int associationId);
    Task<decimal> GetBalanceByAssetIdAsync(int? assetId, int tenantId, int associationId);
}
