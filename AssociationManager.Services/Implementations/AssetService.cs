using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class AssetService : IAssetService
{
    private readonly IAssetRepository _assetRepository;
    private readonly IOccupancyRepository _occupancyRepository;
    private readonly ITenantContext _tenantContext;

    public AssetService(IAssetRepository assetRepository, IOccupancyRepository occupancyRepository, ITenantContext tenantContext)
    {
        _assetRepository = assetRepository;
        _occupancyRepository = occupancyRepository;
        _tenantContext = tenantContext;
    }

    public async Task<Asset?> GetByIdAsync(int id)
    {
        return await _assetRepository.GetByIdAsync(id, _tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<IEnumerable<Asset>> GetHierarchyAsync(int? userId = null)
    {
        var allAssets = (await _assetRepository.GetHierarchyAsync(_tenantContext.TenantId, _tenantContext.AssociationId)).ToList();
        
        // Filter if userId is provided (Resident Mode)
        if (userId.HasValue)
        {
            var userOccupancies = await _occupancyRepository.GetByUserIdAsync(userId.Value, _tenantContext.TenantId, _tenantContext.AssociationId);
            var userAssetIds = userOccupancies.Select(o => o.AssetId).ToHashSet();

            // Find all ancestors of these assets so we can build the path
            var accessibleAssetIds = new HashSet<int>();
            foreach (var assetId in userAssetIds)
            {
                AddAssetAndAncestors(assetId, allAssets, accessibleAssetIds);
            }

            allAssets = allAssets.Where(a => accessibleAssetIds.Contains(a.AssetId)).ToList();
        }

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

    private void AddAssetAndAncestors(int assetId, List<Asset> allAssets, HashSet<int> result)
    {
        if (result.Contains(assetId)) return;
        
        var asset = allAssets.FirstOrDefault(a => a.AssetId == assetId);
        if (asset == null) return;

        result.Add(assetId);
        if (asset.ParentId.HasValue)
        {
            AddAssetAndAncestors(asset.ParentId.Value, allAssets, result);
        }
    }

    public async Task<int> CreateAsync(Asset asset)
    {
        asset.TenantId = _tenantContext.TenantId;
        asset.AssociationId = _tenantContext.AssociationId;
        asset.CreatedBy = _tenantContext.UserId;
        return await _assetRepository.CreateAsync(asset);
    }

    public async Task<int> BulkCreateAsync(BulkCreateRequest request)
    {
        int count = 0;
        switch (request.TemplateType)
        {
            case AssetTemplateType.ResidentialBuilding:
                count = await CreateResidentialBuilding(request);
                break;
            case AssetTemplateType.VillaCommunity:
                count = await CreateBulkAssetsByType(request, AssetType.Villa, "Villa");
                break;
            case AssetTemplateType.BulkUnits:
                count = await CreateBulkAssetsByType(request, AssetType.Unit, "Unit");
                break;
            case AssetTemplateType.Floors:
                count = await CreateBulkAssetsByType(request, AssetType.Floor, "Floor");
                break;
            case AssetTemplateType.CommonAreas:
                count = await CreateBulkAssetsByType(request, AssetType.CommonArea, "Common Area");
                break;
            case AssetTemplateType.Amenities:
                count = await CreateBulkAssetsByType(request, AssetType.Amenity, "Amenity");
                break;
            case AssetTemplateType.SecurityGates:
                count = await CreateBulkAssetsByType(request, AssetType.SecurityGate, "Security Gate");
                break;
        }
        return count;
    }

    private async Task<int> CreateResidentialBuilding(BulkCreateRequest request)
    {
        var building = new Asset
        {
            Name = request.BaseName,
            AssetType = AssetType.Building,
            Description = request.Description ?? "Auto-generated residential building",
            ParentId = request.ParentId,
            TenantId = _tenantContext.TenantId,
            AssociationId = _tenantContext.AssociationId,
            CreatedBy = _tenantContext.UserId
        };
        var buildingId = await _assetRepository.CreateAsync(building);
        int totalCreated = 1;

        int floors = request.NumberOfFloors ?? 0;
        int unitsPerFloor = request.UnitsPerFloor ?? 0;

        for (int f = 1; f <= floors; f++)
        {
            var floor = new Asset
            {
                Name = $"Floor {f}",
                AssetType = AssetType.Floor,
                ParentId = buildingId,
                TenantId = _tenantContext.TenantId,
                AssociationId = _tenantContext.AssociationId,
                CreatedBy = _tenantContext.UserId
            };
            var floorId = await _assetRepository.CreateAsync(floor);
            totalCreated++;

            for (int u = 1; u <= unitsPerFloor; u++)
            {
                var unit = new Asset
                {
                    Name = $"Unit {f}{u:D2}",
                    AssetType = AssetType.Unit,
                    ParentId = floorId,
                    TenantId = _tenantContext.TenantId,
                    AssociationId = _tenantContext.AssociationId,
                    CreatedBy = _tenantContext.UserId,
                    Description = "Auto-generated unit",
                    MetadataJson = SerializeMetadata(request)
                };
                await _assetRepository.CreateAsync(unit);
                totalCreated++;
            }
        }
        return totalCreated;
    }

    private string? SerializeMetadata(BulkCreateRequest request)
    {
        if (string.IsNullOrEmpty(request.RoomConfig) && !request.TotalAreaSqFt.HasValue && string.IsNullOrEmpty(request.BaseAddress))
            return null;

        var metadata = new Dictionary<string, object?>();
        if (!string.IsNullOrEmpty(request.RoomConfig)) metadata["RoomConfig"] = request.RoomConfig;
        if (request.TotalAreaSqFt.HasValue) metadata["TotalAreaSqFt"] = request.TotalAreaSqFt;
        if (!string.IsNullOrEmpty(request.BaseAddress)) metadata["Address"] = request.BaseAddress;

        return System.Text.Json.JsonSerializer.Serialize(metadata);
    }

    private async Task<int> CreateBulkAssetsByType(BulkCreateRequest request, AssetType type, string defaultNamePrefix)
    {
        int quantity = request.Quantity ?? 0;
        int totalCreated = 0;
        string? metadataJson = SerializeMetadata(request);

        for (int i = 1; i <= quantity; i++)
        {
            var asset = new Asset
            {
                Name = $"{request.BaseName} {defaultNamePrefix} {i}",
                AssetType = type,
                ParentId = request.ParentId,
                Description = request.Description ?? $"Auto-generated {defaultNamePrefix}",
                MetadataJson = metadataJson,
                TenantId = _tenantContext.TenantId,
                AssociationId = _tenantContext.AssociationId,
                CreatedBy = _tenantContext.UserId
            };
            await _assetRepository.CreateAsync(asset);
            totalCreated++;
        }
        return totalCreated;
    }

    public async Task<bool> UpdateAsync(Asset asset)
    {
        asset.TenantId = _tenantContext.TenantId;
        asset.AssociationId = _tenantContext.AssociationId;
        return await _assetRepository.UpdateAsync(asset);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        return await _assetRepository.DeleteAsync(id, _tenantContext.TenantId, _tenantContext.AssociationId);
    }
}
