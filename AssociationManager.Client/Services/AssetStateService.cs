using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Client.Services;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using AssociationManager.Shared.Interfaces;
using BlazorBootstrap;

namespace AssociationManager.Client.Services
{
    public class AssetStateService
    {
        private readonly ApiService _api;
        private readonly AuthenticationStateProvider _authStateProvider;
        private readonly IAppAuthorizationService _authService;
        private readonly ToastService _toastService;

        public AssetStateService(
            ApiService api, 
            AuthenticationStateProvider authStateProvider,
            IAppAuthorizationService authService,
            ToastService toastService)
        {
            _api = api;
            _authStateProvider = authStateProvider;
            _authService = authService;
            _toastService = toastService;
        }

        public event Action? OnChange;
        private void NotifyStateChanged() => OnChange?.Invoke();

        // State
        public List<Asset>? Hierarchy { get; private set; }
        public Asset? SelectedAsset { get; set; }
        public bool IsNew { get; set; }
        public string ActiveTab { get; set; } = "details";
        public bool ShowDetailOnMobile { get; set; }
        public bool IsSidebarCollapsed { get; set; }
        public HashSet<int> ExpandedIds { get; } = new();

        // Unit-specific Data
        public List<Occupancy>? Occupants { get; private set; }
        public List<Vehicle>? Vehicles { get; private set; }
        public List<Pet>? Pets { get; private set; }
        public IEnumerable<WorkOrder>? WorkOrders { get; private set; }
        public IEnumerable<Invoice>? Invoices { get; private set; }
        public ResidentDashboardMetrics? AssetMetrics { get; private set; }

        public bool CanManageAssets { get; private set; }
        public bool CanAddGlobalAssets { get; private set; }
        public bool IsResident { get; private set; }

        public async Task InitializePermissionsAsync()
        {
            var authState = await _authStateProvider.GetAuthenticationStateAsync();
            CanAddGlobalAssets = await _authService.HasLevelAsync(authState.User, AppRole.LevelAssociationAdmin);
            CanManageAssets = CanAddGlobalAssets;
            IsResident = !CanAddGlobalAssets;
            NotifyStateChanged();
        }

        public async Task LoadHierarchyAsync()
        {
            Hierarchy = await _api.GetAsync<List<Asset>>("api/assets/hierarchy");
            
            if (SelectedAsset != null && !IsNew)
            {
                SelectedAsset = FindInHierarchy(Hierarchy, SelectedAsset.AssetId);
            }
            NotifyStateChanged();
        }

        public async Task SelectAssetAsync(Asset asset)
        {
            SelectedAsset = asset;
            IsNew = false;
            ActiveTab = "details";
            ShowDetailOnMobile = true;
            
            if (IsUnitType(asset.AssetType))
            {
                await LoadUnitDataAsync(asset.AssetId);
            }
            NotifyStateChanged();
        }

        public async Task LoadUnitDataAsync(int assetId)
        {
            CanManageAssets = await _api.GetAsync<bool>($"api/people/can-manage-unit/{assetId}");
            
            Occupants = await _api.GetAsync<List<Occupancy>>($"api/people/unit/{assetId}/occupants");
            Vehicles = await _api.GetAsync<List<Vehicle>>($"api/people/unit/{assetId}/vehicles");
            Pets = await _api.GetAsync<List<Pet>>($"api/people/unit/{assetId}/pets");
            
            WorkOrders = await _api.GetAsync<List<WorkOrder>>($"api/operations/workorders?assetId={assetId}");
            var invoiceResult = await _api.GetAsync<PagedResult<Invoice>>($"api/finance/invoices?assetId={assetId}");
            Invoices = invoiceResult?.Items;

            AssetMetrics = await _api.GetAsync<ResidentDashboardMetrics>($"api/dashboard/resident/metrics?assetId={assetId}");
            NotifyStateChanged();
        }

        public async Task<bool> SaveAssetAsync()
        {
            if (SelectedAsset == null) return false;

            bool success;
            if (IsNew)
            {
                success = await _api.PostAsync("api/assets", SelectedAsset);
                if (success) _toastService.Notify(new(ToastType.Success, "New asset created."));
            }
            else
            {
                success = await _api.PutAsync($"api/assets/{SelectedAsset.AssetId}", SelectedAsset);
                if (success) _toastService.Notify(new(ToastType.Success, "Asset updated."));
            }

            if (success)
            {
                await LoadHierarchyAsync();
                IsNew = false;
                NotifyStateChanged();
            }
            return success;
        }

        public async Task<bool> DeleteAssetAsync()
        {
            if (SelectedAsset == null) return false;
            var success = await _api.DeleteAsync($"api/assets/{SelectedAsset.AssetId}");
            if (success)
            {
                _toastService.Notify(new(ToastType.Warning, "Asset deleted."));
                SelectedAsset = null;
                await LoadHierarchyAsync();
                NotifyStateChanged();
            }
            return success;
        }

        public void ToggleExpand(int assetId)
        {
            if (ExpandedIds.Contains(assetId))
                ExpandedIds.Remove(assetId);
            else
                ExpandedIds.Add(assetId);
            NotifyStateChanged();
        }

        private Asset? FindInHierarchy(IEnumerable<Asset>? assets, int id)
        {
            if (assets == null) return null;
            foreach (var asset in assets)
            {
                if (asset.AssetId == id) return asset;
                var found = FindInHierarchy(asset.Children, id);
                if (found != null) return found;
            }
            return null;
        }

        public bool IsUnitType(AssociationManager.Shared.Enums.AssetType type) => type == AssociationManager.Shared.Enums.AssetType.Unit || type == AssociationManager.Shared.Enums.AssetType.Villa;

        public void CreateRootProperty()
        {
            SelectedAsset = new Asset { AssetType = AssetType.Property };
            IsNew = true;
            ActiveTab = "details";
            ShowDetailOnMobile = true;
            NotifyStateChanged();
        }

        public void CreateChild()
        {
            if (SelectedAsset == null) return;
            var parentId = SelectedAsset.AssetId;
            SelectedAsset = new Asset 
            { 
                ParentId = parentId,
                AssetType = GetDefaultChildType(SelectedAsset.AssetType)
            };
            IsNew = true;
            ActiveTab = "details";
            ShowDetailOnMobile = true;
            NotifyStateChanged();
        }

        private AssetType GetDefaultChildType(AssetType parentType) => parentType switch
        {
            AssetType.Property => AssetType.Building,
            AssetType.Building => AssetType.Floor,
            AssetType.Floor => AssetType.Unit,
            _ => AssetType.Unit
        };
    }
}
