using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Client.Services;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using AssociationManager.Shared.Interfaces;
using BlazorBootstrap;

namespace AssociationManager.Client.Services
{
    public class TariffStateService
    {
        private readonly ApiService _api;
        private readonly AuthenticationStateProvider _authStateProvider;
        private readonly NavigationManager _navigation;
        private readonly ToastService _toastService;
        private readonly ITenantContext _tenantContext;
        private int _lastAssociationId;

        public TariffStateService(
            ApiService api, 
            AuthenticationStateProvider authStateProvider, 
            NavigationManager navigation,
            ToastService toastService,
            ITenantContext tenantContext)
        {
            _api = api;
            _authStateProvider = authStateProvider;
            _navigation = navigation;
            _toastService = toastService;
            _tenantContext = tenantContext;
            
            ParseQueryParameters();
        }

        public event Action? OnChange;
        private void NotifyStateChanged() => OnChange?.Invoke();

        // State
        public string Scope { get; private set; } = "tenant";
        public List<TariffGroup>? Groups { get; private set; }
        public TariffGroup? SelectedGroup { get; private set; }
        public int SelectedLayerId { get; set; }
        public List<TariffLayer>? Layers { get; private set; }
        public List<AssetTariff>? AssignedAssets { get; private set; }
        public List<Asset>? AllPossibleAssets { get; private set; }
        
        public string GroupFilter { get; set; } = "";
        public string AssetFilter { get; set; } = "";
        private string _activeTab = "layers";
        public string ActiveTab 
        { 
            get => _activeTab; 
            set { _activeTab = value; NotifyStateChanged(); } 
        }

        private bool _showWorkbenchOnMobile;
        public bool ShowWorkbenchOnMobile 
        { 
            get => _showWorkbenchOnMobile; 
            set { _showWorkbenchOnMobile = value; NotifyStateChanged(); } 
        }
        
        // Modal State
        private bool _showGroupModal;
        public bool ShowGroupModal 
        { 
            get => _showGroupModal; 
            set { _showGroupModal = value; NotifyStateChanged(); } 
        }

        private bool _showLayerModal;
        public bool ShowLayerModal 
        { 
            get => _showLayerModal; 
            set { _showLayerModal = value; NotifyStateChanged(); } 
        }

        private bool _showBulkAssignModal;
        public bool ShowBulkAssignModal 
        { 
            get => _showBulkAssignModal; 
            set { _showBulkAssignModal = value; NotifyStateChanged(); } 
        }
        
        public TariffGroup NewGroup { get; set; } = new();
        public TariffLayer NewLayer { get; set; } = new();

        public void ToggleGroupModal(bool show)
        {
            if (show) NewGroup = new();
            ShowGroupModal = show;
        }

        public void ToggleLayerModal(bool show)
        {
            if (show) NewLayer = new();
            ShowLayerModal = show;
        }

        public void ToggleBulkAssignModal(bool show)
        {
            ShowBulkAssignModal = show;
        }

        public bool ParseQueryParameters()
        {
            var uri = new Uri(_navigation.Uri);
            var query = uri.Query.TrimStart('?');
            var parts = query.Split('&', StringSplitOptions.RemoveEmptyEntries);
            
            string newScope = "tenant";
            int newLayerId = 0;

            foreach (var part in parts)
            {
                var kvp = part.Split('=');
                if (kvp.Length == 2)
                {
                    if (kvp[0].Equals("scope", StringComparison.OrdinalIgnoreCase)) newScope = kvp[1];
                    else if (kvp[0].Equals("layerId", StringComparison.OrdinalIgnoreCase) && int.TryParse(kvp[1], out int lid)) newLayerId = lid;
                }
            }

            // DETECT CHANGE: Check both URL parameters AND the background Association context
            bool contextChanged = _tenantContext.AssociationId != _lastAssociationId;

            if (newScope != Scope || newLayerId != SelectedLayerId || contextChanged)
            {
                Scope = newScope;
                SelectedLayerId = newLayerId;
                
                // RESET STATE: Clear lists to trigger spinners and avoid stale data
                ResetState();
                return true;
            }
            return false;
        }

        public void ResetState()
        {
            Groups = null;
            Layers = null;
            AssignedAssets = null;
            AllPossibleAssets = null;
            SelectedGroup = null;
            SelectedLayerId = 0;
            NotifyStateChanged();
        }

        public async Task LoadGroupsAsync()
        {
            try 
            {
                Groups = null; // Ensure spinner starts
                NotifyStateChanged();
                
                // Capture the ID we are loading for
                _lastAssociationId = _tenantContext.AssociationId;
                
                string url = "api/tariff/groups";
                if (Scope == "association")
                {
                    var aid = _tenantContext.AssociationId;
                    if (aid != 0) url = $"{url}?associationId={aid}";
                }
                var result = await _api.GetAsync<List<TariffGroup>>(url);
                Groups = result ?? new List<TariffGroup>();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Tariff] Error loading groups: {ex.Message}");
                _toastService.Notify(new(ToastType.Danger, $"Failed to load groups: {ex.Message}"));
                Groups = new List<TariffGroup>();
            }
            finally
            {
                NotifyStateChanged();
            }
        }

        public async Task SelectGroupAsync(TariffGroup group)
        {
            SelectedGroup = group;
            Layers = null;
            SelectedLayerId = 0;
            ShowWorkbenchOnMobile = true;
            NotifyStateChanged();
            
            Layers = await _api.GetAsync<List<TariffLayer>>($"api/tariff/groups/{group.TariffGroupId}/layers");
            NotifyStateChanged();
        }

        public async Task LoadAssignedAssetsAsync(int layerId)
        {
            AssignedAssets = null; // Clear to trigger loading state and avoid stale filters
            if (layerId == 0) 
            {
                return;
            }

            await LoadAllPossibleAssetsAsync();
            
            // TARGETED FETCH: Optimized to current layer
            var assignments = await _api.GetAsync<List<AssetTariff>>($"api/tariff/layers/{layerId}/assignments?associationId={_tenantContext.AssociationId}");
            if (assignments != null && AllPossibleAssets != null)
            {
                foreach (var a in assignments)
                {
                    var asset = AllPossibleAssets.FirstOrDefault(x => x.AssetId == a.AssetId);
                    if (asset != null) a.AssetName = asset.Name;
                }
                AssignedAssets = assignments;
            }
            else
            {
                AssignedAssets = new List<AssetTariff>();
            }
            NotifyStateChanged();
        }

        public async Task LoadAllPossibleAssetsAsync()
        {
            if (AllPossibleAssets != null) return;
            
            var aid = _tenantContext.AssociationId;
            if (aid != 0)
            {
                var assets = await _api.GetAsync<List<Asset>>($"api/assets/hierarchy?associationId={aid}");
                if (assets != null)
                {
                    AllPossibleAssets = Flatten(assets)
                        .Where(a => a.AssetType == AssetType.Unit || a.AssetType == AssetType.Villa || a.AssetType == AssetType.Property)
                        .ToList();
                }
            }
            NotifyStateChanged();
        }

        public async Task CreateGroupAsync()
        {
            if (string.IsNullOrWhiteSpace(NewGroup.Name)) return;

            // Ensure AssociationId is explicitly set if in association scope
            if (Scope == "association")
            {
                NewGroup.AssociationId = _tenantContext.AssociationId;
            }

            var success = await _api.PostAsync("api/tariff/groups", NewGroup);
            if (success)
            {
                _toastService.Notify(new(ToastType.Success, "Billing group created."));
                ShowGroupModal = false;
                await LoadGroupsAsync();
            }
            else
            {
                _toastService.Notify(new(ToastType.Danger, "Failed to create billing group. Permissions or constraints might be blocking this action."));
            }
        }

        public async Task CreateLayerAsync()
        {
            if (string.IsNullOrWhiteSpace(NewLayer.Name) || SelectedGroup == null) return;
            NewLayer.TariffGroupId = SelectedGroup.TariffGroupId;

            // Ensure AssociationId is inherited from Group or Context
            NewLayer.AssociationId = SelectedGroup.AssociationId ?? _tenantContext.AssociationId;

            var success = await _api.PostAsync("api/tariff/layers", NewLayer);
            if (success)
            {
                _toastService.Notify(new(ToastType.Success, "Tariff layer added."));
                ShowLayerModal = false;
                await SelectGroupAsync(SelectedGroup);
            }
            else
            {
                _toastService.Notify(new(ToastType.Danger, "Failed to create tariff layer."));
            }
        }

        public async Task DeleteLayerAsync(int id)
        {
            var success = await _api.DeleteAsync($"api/tariff/layers/{id}");
            if (success)
            {
                _toastService.Notify(new(ToastType.Warning, "Tariff layer deleted."));
                if (SelectedGroup != null) await SelectGroupAsync(SelectedGroup);
            }
        }

        private async Task<int> GetAssociationIdAsync()
        {
            var authState = await _authStateProvider.GetAuthenticationStateAsync();
            var aid = authState.User.FindFirst("AssociationId")?.Value;
            return int.TryParse(aid, out int associationId) ? associationId : 0;
        }

        private IEnumerable<Asset> Flatten(IEnumerable<Asset> assets)
        {
            foreach (var asset in assets)
            {
                yield return asset;
                if (asset.Children != null)
                {
                    foreach (var child in Flatten(asset.Children)) yield return child;
                }
            }
        }
    }
}
