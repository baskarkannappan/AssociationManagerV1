using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class TariffService : ITariffService
{
    private readonly ITariffRepository _tariffRepository;
    private readonly ILedgerService _ledgerService;
    private readonly ITenantContext _tenantContext;

    public TariffService(ITariffRepository tariffRepository, ILedgerService ledgerService, ITenantContext tenantContext)
    {
        _tariffRepository = tariffRepository;
        _ledgerService = ledgerService;
        _tenantContext = tenantContext;
    }

    public async Task<IEnumerable<TariffGroup>> GetTariffGroupsAsync()
    {
        return await _tariffRepository.GetGroupsByTenantIdAsync(_tenantContext.TenantId);
    }

    public async Task<int> CreateTariffGroupAsync(TariffGroup group)
    {
        group.TenantId = _tenantContext.TenantId;
        return await _tariffRepository.CreateGroupAsync(group);
    }

    public async Task<bool> UpdateTariffGroupAsync(TariffGroup group)
    {
        return await _tariffRepository.UpdateGroupAsync(group);
    }

    public async Task<bool> DeleteTariffGroupAsync(int groupId)
    {
        return await _tariffRepository.DeleteGroupAsync(groupId);
    }

    public async Task<IEnumerable<TariffLayer>> GetTariffLayersAsync(int groupId)
    {
        return await _tariffRepository.GetLayersByGroupIdAsync(groupId);
    }

    public async Task<int> CreateTariffLayerAsync(TariffLayer layer)
    {
        layer.TenantId = _tenantContext.TenantId;
        return await _tariffRepository.CreateLayerAsync(layer);
    }

    public async Task<bool> UpdateTariffLayerAsync(TariffLayer layer)
    {
        return await _tariffRepository.UpdateLayerAsync(layer);
    }

    public async Task<bool> DeleteTariffLayerAsync(int layerId)
    {
        return await _tariffRepository.DeleteLayerAsync(layerId);
    }

    public async Task<IEnumerable<AssetTariff>> GetAssetTariffsAsync(int assetId)
    {
        return await _tariffRepository.GetTariffsByAssetIdAsync(assetId);
    }

    public async Task<bool> AssignTariffToAssetAsync(AssetTariff assetTariff)
    {
        return await _tariffRepository.UpsertAssetTariffAsync(assetTariff);
    }

    public async Task<bool> RemoveTariffFromAssetAsync(int assetId, int layerId)
    {
        return await _tariffRepository.RemoveAssetTariffAsync(assetId, layerId);
    }

    public async Task GenerateRecurringInvoicesAsync()
    {
        // Get all active assignments for the current association
        var activeAssignments = await _tariffRepository.GetActiveTariffsByTenantIdAsync(_tenantContext.TenantId);
        
        foreach (var assignment in activeAssignments)
        {
            // Implementation logic will go here:
            // 1. Check if due based on frequency
            // 2. Calculate amount
            // 3. await _ledgerService.RecordTransactionAsync(...)
        }

        await Task.CompletedTask;
    }
}
