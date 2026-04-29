using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Client.Services;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using AssociationManager.Shared.Interfaces;
using BlazorBootstrap;

namespace AssociationManager.Client.Services
{
    public class FlatAssetNode
    {
        public Asset Asset { get; set; } = null!;
        public int Level { get; set; }
        public bool IsExpanded { get; set; }
        public bool HasChildren { get; set; }
    }

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
        public string? LoadError { get; private set; }
        
        private Asset? _selectedAsset;
        public Asset? SelectedAsset 
        { 
            get => _selectedAsset; 
            set { _selectedAsset = value; NotifyStateChanged(); } 
        }

        private bool _isNew;
        public bool IsNew 
        { 
            get => _isNew; 
            set { _isNew = value; NotifyStateChanged(); } 
        }

        private string _activeTab = "details";
        public string ActiveTab 
        { 
            get => _activeTab; 
            set { _activeTab = value; NotifyStateChanged(); } 
        }

        private bool _showDetailOnMobile;
        public bool ShowDetailOnMobile 
        { 
            get => _showDetailOnMobile; 
            set { _showDetailOnMobile = value; NotifyStateChanged(); } 
        }

        private bool _isSidebarCollapsed;
        public bool IsSidebarCollapsed 
        { 
            get => _isSidebarCollapsed; 
            set { _isSidebarCollapsed = value; NotifyStateChanged(); } 
        }

        public HashSet<int> ExpandedIds { get; } = new();
        public List<FlatAssetNode> VisibleNodes { get; private set; } = new();
        private string _searchTerm = "";
        public string SearchTerm 
        { 
            get => _searchTerm; 
            set { _searchTerm = value; RefreshVisibleNodes(); NotifyStateChanged(); } 
        }

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
            try
            {
                LoadError = null;
                // Initial load only fetches root assets (parentId = null)
                var roots = await _api.GetAsync<List<Asset>>("api/assets/hierarchy");
                
                if (roots == null)
                {
                    Hierarchy = new List<Asset>();
                    LoadError = "Failed to load root assets. Please check your connection or permissions.";
                }
                else
                {
                    // If we already have a hierarchy, try to preserve expanded state and children
                    if (Hierarchy != null && Hierarchy.Any())
                    {
                        await SyncChildrenRecursive(roots);
                    }
                    Hierarchy = roots;
                }
                
                if (SelectedAsset != null && !IsNew)
                {
                    SelectedAsset = FindInHierarchy(Hierarchy, SelectedAsset.AssetId);
                }
            }
            catch (Exception ex)
            {
                Hierarchy = new List<Asset>();
                LoadError = $"Error: {ex.Message}";
            }
            finally
            {
                RefreshVisibleNodes();
                NotifyStateChanged();
            }
        }

        private async Task SyncChildrenRecursive(List<Asset> newAssets)
        {
            foreach (var asset in newAssets)
            {
                if (ExpandedIds.Contains(asset.AssetId))
                {
                    // Fetch children for this expanded node
                    var children = await _api.GetAsync<List<Asset>>($"api/assets/hierarchy?parentId={asset.AssetId}");
                    if (children != null)
                    {
                        asset.Children = children;
                        await SyncChildrenRecursive(asset.Children);
                    }
                }
            }
        }

        public async Task SelectAssetAsync(Asset asset)
        {
            var fullAsset = await _api.GetAsync<Asset>($"api/assets/{asset.AssetId}");
            SelectedAsset = fullAsset ?? asset;
            IsNew = false;
            ActiveTab = "details";
            ShowDetailOnMobile = true;
            
            if (IsUnitType(SelectedAsset.AssetType))
            {
                await LoadUnitDataAsync(SelectedAsset.AssetId);
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

        public async Task ToggleExpand(int assetId)
        {
            if (ExpandedIds.Contains(assetId))
            {
                ExpandedIds.Remove(assetId);
            }
            else
            {
                ExpandedIds.Add(assetId);
                
                // Lazy Load: If children aren't already loaded, fetch them from the server
                var parent = FindInHierarchy(Hierarchy, assetId);
                if (parent != null && (parent.Children == null || !parent.Children.Any()))
                {
                    var children = await _api.GetAsync<List<Asset>>($"api/assets/hierarchy?parentId={assetId}");
                    if (children != null)
                    {
                        parent.Children = children;
                    }
                }
            }
            RefreshVisibleNodes();
            NotifyStateChanged();
        }

        public void RefreshVisibleNodes()
        {
            var nodes = new List<FlatAssetNode>();
            if (Hierarchy != null)
            {
                foreach (var root in Hierarchy)
                {
                    Flatten(root, 0, nodes);
                }
            }
            VisibleNodes = nodes;
        }

        private void Flatten(Asset asset, int level, List<FlatAssetNode> result)
        {
            bool matchesSearch = string.IsNullOrWhiteSpace(SearchTerm) || 
                                asset.Name.Contains(SearchTerm, StringComparison.OrdinalIgnoreCase);

            // In search mode, we show everything that matches or has matching children
            // For now, simple implementation: if search is active, show only matching or their parents
            // For normal mode: show if parent is expanded
            
            var node = new FlatAssetNode
            {
                Asset = asset,
                Level = level,
                IsExpanded = ExpandedIds.Contains(asset.AssetId),
                HasChildren = CanHaveChildren(asset.AssetType)
            };

            bool shouldShow = string.IsNullOrWhiteSpace(SearchTerm) || matchesSearch || ChildrenMatch(asset, SearchTerm);

            if (shouldShow)
            {
                result.Add(node);
                if (node.IsExpanded || !string.IsNullOrWhiteSpace(SearchTerm))
                {
                    if (asset.Children != null)
                    {
                        foreach (var child in asset.Children)
                        {
                            Flatten(child, level + 1, result);
                        }
                    }
                }
            }
        }

        private bool ChildrenMatch(Asset asset, string term)
        {
            if (asset.Children == null) return false;
            return asset.Children.Any(c => c.Name.Contains(term, StringComparison.OrdinalIgnoreCase) || ChildrenMatch(c, term));
        }

        private bool CanHaveChildren(AssetType type) => type != AssetType.Unit && type != AssetType.Villa && type != AssetType.Amenity;

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
