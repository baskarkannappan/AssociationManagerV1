using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class AssetService : IAssetService
{
    private readonly IAssetRepository _assetRepository;
    private readonly ITenantContext _tenantContext;

    public AssetService(IAssetRepository assetRepository, ITenantContext tenantContext)
    {
        _assetRepository = assetRepository;
        _tenantContext = tenantContext;
    }

    private int CurrentTenantId => _tenantContext.TenantId != 0 ? _tenantContext.TenantId : 0;

    public async Task<Asset?> GetByIdAsync(int id)
    {
        return await _assetRepository.GetByIdAsync(id, CurrentTenantId);
    }

    public async Task<IEnumerable<Asset>> GetHierarchyAsync()
    {
        var allAssets = (await _assetRepository.GetHierarchyAsync(CurrentTenantId)).ToList();
        
        // Build hierarchy in memory
        var lookup = allAssets.ToLookup(a => a.ParentId);
        var rootAssets = lookup[null].ToList();

        void AddChildren(Asset parent)
        {
            parent.Children = lookup[parent.AssetId].ToList();
            foreach (var child in parent.Children)
            {
                AddChildren(child);
            }
        }

        foreach (var root in rootAssets)
        {
            AddChildren(root);
        }

        return rootAssets;
    }

    public async Task<int> CreateAsync(Asset asset)
    {
        asset.TenantId = CurrentTenantId;
        asset.CreatedBy = _tenantContext.UserId;
        return await _assetRepository.CreateAsync(asset);
    }

    public async Task<bool> UpdateAsync(Asset asset)
    {
        asset.TenantId = CurrentTenantId;
        return await _assetRepository.UpdateAsync(asset);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        return await _assetRepository.DeleteAsync(id, CurrentTenantId);
    }
}
