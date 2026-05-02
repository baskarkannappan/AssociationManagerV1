using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface ITariffService
{
    // Group & Layer Management
    Task<IEnumerable<TariffGroup>> GetTariffGroupsAsync(int? associationId = null);
    Task<int> CreateTariffGroupAsync(TariffGroup group);
    Task<bool> UpdateTariffGroupAsync(TariffGroup group);
    Task<bool> DeleteTariffGroupAsync(int groupId);

    Task<IEnumerable<TariffLayer>> GetTariffLayersAsync(int groupId);
    Task<int> CreateTariffLayerAsync(TariffLayer layer);
    Task<bool> UpdateTariffLayerAsync(TariffLayer layer);
    Task<bool> DeleteTariffLayerAsync(int layerId);

    // Assignment
    Task<IEnumerable<AssetTariff>> GetAssetTariffsAsync(int assetId);
    Task<IEnumerable<AssetTariff>> GetLayerAssignmentsAsync(int layerId);
    Task<bool> AssignTariffToAssetAsync(AssetTariff assignment);
    Task<bool> BulkAssignTariffsAsync(IEnumerable<AssetTariff> assignments);
    Task<IEnumerable<Asset>> GetAvailableAssetsForLayerAsync(int associationId, int layerId);
    Task<bool> UnassignTariffFromAssetAsync(int assetId, int layerId);

    // Automation & Billing
    Task GenerateRecurringInvoicesAsync();
}
