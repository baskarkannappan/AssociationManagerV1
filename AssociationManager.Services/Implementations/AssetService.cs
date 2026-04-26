using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using AssociationManager.Realtime.Hubs;
using System.Net.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;

namespace AssociationManager.Services.Implementations;

public class AssetService : IAssetService
{
    private readonly IAssetRepository _assetRepository;
    private readonly IOccupancyRepository _occupancyRepository;
    private readonly ITenantContext _tenantContext;
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    public AssetService(
        IAssetRepository assetRepository, 
        IOccupancyRepository occupancyRepository, 
        ITenantContext tenantContext,
        IHubContext<NotificationHub> hubContext,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration)
    {
        _assetRepository = assetRepository;
        _occupancyRepository = occupancyRepository;
        _tenantContext = tenantContext;
        _hubContext = hubContext;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    public async Task<Asset?> GetByIdAsync(int id)
    {
        return await _assetRepository.GetByIdAsync(id, _tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<IEnumerable<Asset>> GetAllAsync()
    {
        return await _assetRepository.GetHierarchyAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<IEnumerable<Asset>> GetHierarchyAsync(int? userId = null, int? parentId = null)
    {
        // For 10M asset scaling, we transition from full memory-tree build to lazy-loading.
        // We fetch only the requested slice (roots or children of a specific parent).
        // Identity filtering is now handled in SQL (recursive) for maximum performance.
        return await _assetRepository.GetHierarchyAsync(_tenantContext.TenantId, _tenantContext.AssociationId, parentId, userId);
    }

    private async Task AddAssetAndAncestors(int assetId, List<Asset> allAssets, HashSet<int> result)
    {
        if (result.Contains(assetId)) return;
        
        var asset = allAssets.FirstOrDefault(a => a.AssetId == assetId);
        if (asset == null) return;

        result.Add(assetId);
        if (asset.ParentId.HasValue)
        {
            await AddAssetAndAncestors(asset.ParentId.Value, allAssets, result);
        }
    }

    private async Task<int?> ValidateParentIdAsync(int? parentId)
    {
        if (!parentId.HasValue) return null;
        
        var parent = await _assetRepository.GetByIdAsync(parentId.Value, _tenantContext.TenantId, _tenantContext.AssociationId);
        return parent?.AssetId; // Returns ID if parent belongs to current Association, else null
    }

    public async Task<int> CreateAsync(Asset asset)
    {
        asset.TenantId = _tenantContext.TenantId;
        asset.AssociationId = _tenantContext.AssociationId;
        asset.CreatedBy = _tenantContext.UserId;
        
        // Permanent Fix: Ensure Parent belongs to the same association
        asset.ParentId = await ValidateParentIdAsync(asset.ParentId);
        
        return await _assetRepository.CreateAsync(asset);
    }

    public async Task<int> BulkCreateAsync(BulkCreateRequest request)
    {
        var assets = new List<Asset>();
        // Templates that require custom hierarchical logic
        if (request.TemplateType == AssetTemplateType.VillaCommunity)
        {
            assets = await BuildVillaCommunityNodes(request);
        }
        else if (request.TemplateType == AssetTemplateType.ResidentialBuilding)
        {
            assets = await BuildBuildingFloorRoomNodes(request);
        }
        else
        {
            assets = await BuildBulkNodes(request);
        }

        if (!assets.Any()) return 0;
        return await _assetRepository.BulkCreateAsync(assets);
    }

    public async Task ProcessBulkCreateJobAsync(int tenantId, int associationId, int userId, BulkCreateRequest request)
    {
        bool isWorker = false;
        // Background job runs on a thread without HTTP context. 
        // We must manually initialize the context to ensure the subsequent service calls use the correct IDs.
        _tenantContext.SetContext(tenantId, associationId, userId);
        isWorker = true;

        // Background job uses the request data already populated with Tenant/Association context
        await BulkCreateAsync(request);
        
        if (isWorker)
        {
            // If running in Worker, call the API to broadcast SignalR notification
            // Worker is isolated, so its _hubContext has no clients.
            try
            {
                var apiUrl = _configuration["AssociationApiUrl"] ?? "https://localhost:5001";
                var client = _httpClientFactory.CreateClient();
                var response = await client.PostAsync($"{apiUrl}/api/internal/broadcast/hierarchy-changed/{associationId}", null);
                if (!response.IsSuccessStatusCode)
                {
                    System.Console.WriteLine($"[AssetService] Failed to broadcast hierarchy change. Status: {response.StatusCode}");
                }
            }
            catch (System.Exception ex)
            {
                System.Console.WriteLine($"[AssetService] Error broadcasting hierarchy change: {ex.Message}");
            }
        }
        else
        {
            // If running in same process (e.g. monolithic), use SignalR directly
            await _hubContext.Clients.Group($"Association_{associationId}")
                .SendAsync("ReceiveNotification", "System", $"Bulk creation of {request.Quantity ?? (request.NumberOfFloors * request.UnitsPerFloor)} assets complete.");
                
            await _hubContext.Clients.Group($"Association_{associationId}")
                .SendAsync("HierarchyChanged");
        }
    }

    private async Task<List<Asset>> BuildVillaCommunityNodes(BulkCreateRequest request)
    {
        var result = new List<Asset>();
        int units = request.Quantity ?? 1;
        
        var parentId = await ValidateParentIdAsync(request.ParentId);

        for (int i = 1; i <= units; i++)
        {
            result.Add(new Asset
            {
                Name = $"{request.BaseName} {i}",
                AssetType = AssetType.Villa,
                ParentId = parentId,
                TenantId = _tenantContext.TenantId,
                AssociationId = _tenantContext.AssociationId,
                CreatedBy = _tenantContext.UserId,
                CreatedDate = System.DateTime.Now,
                IsActive = true,
                Description = "Auto-generated villa",
                MetadataJson = SerializeMetadata(request)
            });
        }
        return result;
    }

    private async Task<List<Asset>> BuildBuildingFloorRoomNodes(BulkCreateRequest request)
    {
        var result = new List<Asset>();
        int floors = request.NumberOfFloors ?? 1;
        int unitsPerFloor = request.UnitsPerFloor ?? 1;
        
        // Create Building Root
        var building = new Asset
        {
            Name = request.BaseName ?? "Building",
            AssetType = AssetType.Building,
            ParentId = await ValidateParentIdAsync(request.ParentId),
            TenantId = _tenantContext.TenantId,
            AssociationId = _tenantContext.AssociationId,
            CreatedBy = _tenantContext.UserId,
            CreatedDate = System.DateTime.Now,
            IsActive = true,
            Description = request.Description ?? "Auto-generated building"
        };
        
        var buildingId = await _assetRepository.CreateAsync(building);

        for (int f = 1; f <= floors; f++)
        {
            var floor = new Asset
            {
                Name = $"Floor {f}",
                AssetType = AssetType.Floor,
                ParentId = buildingId,
                TenantId = _tenantContext.TenantId,
                AssociationId = _tenantContext.AssociationId,
                CreatedBy = _tenantContext.UserId,
                CreatedDate = System.DateTime.Now,
                IsActive = true
            };
            
            var floorId = await _assetRepository.CreateAsync(floor);

            for (int u = 1; u <= unitsPerFloor; u++)
            {
                result.Add(new Asset
                {
                    Name = $"Unit {f}{u:D2}",
                    AssetType = AssetType.Unit,
                    ParentId = floorId,
                    TenantId = _tenantContext.TenantId,
                    AssociationId = _tenantContext.AssociationId,
                    CreatedBy = _tenantContext.UserId,
                    CreatedDate = System.DateTime.Now,
                    IsActive = true,
                    Description = "Auto-generated unit",
                    MetadataJson = SerializeMetadata(request)
                });
            }
        }
        return result;
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

    private async Task<List<Asset>> BuildBulkNodes(BulkCreateRequest request)
    {
        var result = new List<Asset>();
        int quantity = request.Quantity ?? 0;
        string? metadataJson = SerializeMetadata(request);
        AssetType type = request.TemplateType switch
        {
            AssetTemplateType.VillaCommunity => AssetType.Villa,
            AssetTemplateType.BulkUnits => AssetType.Unit,
            AssetTemplateType.Floors => AssetType.Floor,
            AssetTemplateType.CommonAreas => AssetType.CommonArea,
            AssetTemplateType.Amenities => AssetType.Amenity,
            AssetTemplateType.SecurityGates => AssetType.SecurityGate,
            _ => AssetType.Unit
        };

        var parentId = await ValidateParentIdAsync(request.ParentId);

        for (int i = 1; i <= quantity; i++)
        {
            result.Add(new Asset
            {
                Name = $"{request.BaseName} {i}",
                AssetType = type,
                ParentId = parentId,
                Description = request.Description ?? "Auto-generated asset",
                MetadataJson = metadataJson,
                TenantId = _tenantContext.TenantId,
                AssociationId = _tenantContext.AssociationId,
                CreatedBy = _tenantContext.UserId,
                CreatedDate = System.DateTime.Now,
                IsActive = true
            });
        }
        return result;
    }

    public async Task<bool> UpdateAsync(Asset asset)
    {
        asset.TenantId = _tenantContext.TenantId;
        asset.AssociationId = _tenantContext.AssociationId;
        
        // Permanent Fix: Ensure Parent belongs to the same association during update
        asset.ParentId = await ValidateParentIdAsync(asset.ParentId);
        
        return await _assetRepository.UpdateAsync(asset);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        return await _assetRepository.DeleteAsync(id, _tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<IEnumerable<dynamic>> GetAssignedTariffsAsync(int assetId)
    {
        return await _assetRepository.GetAssignedTariffsAsync(assetId, _tenantContext.TenantId, _tenantContext.AssociationId);
    }
}
