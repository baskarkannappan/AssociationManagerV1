using AssociationManager.Shared.Models;
using AssociationManager.Client.Services;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using AssociationManager.Shared.Interfaces;
using BlazorBootstrap;
using Microsoft.JSInterop;

namespace AssociationManager.Client.Services
{
    public class BillingStateService
    {
        private readonly ApiService _api;
        private readonly AuthenticationStateProvider _authStateProvider;
        private readonly NavigationManager _navigation;
        private readonly ToastService _toastService;
        private readonly IJSRuntime _js;

        private readonly ITenantContext _tenantContext;
        private int _lastAssociationId;

        public BillingStateService(
            ApiService api, 
            AuthenticationStateProvider authStateProvider, 
            NavigationManager navigation,
            ToastService toastService,
            IJSRuntime js,
            ITenantContext tenantContext)
        {
            _api = api;
            _authStateProvider = authStateProvider;
            _navigation = navigation;
            _toastService = toastService;
            _js = js;
            _tenantContext = tenantContext;
            
            ParseQueryParameters();
        }

        public event Action? OnChange;
        private void NotifyStateChanged() => OnChange?.Invoke();

        // State
        public string Scope { get; private set; } = "tenant";
        public string ActiveTab { get; set; } = "invoices";
        public List<Payment>? RecentPayments { get; private set; }
        public decimal AdvanceBalance { get; private set; }
        public List<BillingBatch>? ExistingBatches { get; private set; }
        
        // Search & Filters
        public string? SearchTerm { get; set; }
        public string? StatusFilter { get; set; }

        // Batch Generation
        public InvoiceBatchRequest BatchRequest { get; private set; } = new() { Month = DateTime.Today.Month, Year = DateTime.Today.Year, DueDate = DateTime.Today.AddDays(15) };
        public InvoiceBatchResult? BatchResult { get; private set; }
        public bool IsProcessingBatch { get; private set; }

        // Modal State
        private bool _showCreateInvoiceModal;
        public bool ShowCreateInvoiceModal 
        { 
            get => _showCreateInvoiceModal; 
            set { _showCreateInvoiceModal = value; NotifyStateChanged(); } 
        }

        private bool _showTransactionHistory;
        public bool ShowTransactionHistory 
        { 
            get => _showTransactionHistory; 
            set { _showTransactionHistory = value; NotifyStateChanged(); } 
        }

        private bool _showAdjustModal;
        public bool ShowAdjustModal 
        { 
            get => _showAdjustModal; 
            set { _showAdjustModal = value; NotifyStateChanged(); } 
        }
        
        public int TargetInvoiceId { get; set; }
        public Invoice? SelectedHistoryInvoice { get; set; }
        public List<PaymentHistoryItem>? HistoryTransactions { get; set; }
        public bool HistoryLoading { get; set; }
        
        public int IdToAdjust { get; set; }
        public Invoice? AdjustingInvoice { get; set; }
        public List<InvoiceLineItem> AdjustingLineItems { get; set; } = new();

        public bool ParseQueryParameters()
        {
            var uri = new Uri(_navigation.Uri);
            var query = uri.Query.TrimStart('?');
            var parts = query.Split('&', StringSplitOptions.RemoveEmptyEntries);
            
            string newScope = "tenant";

            foreach (var part in parts)
            {
                var kvp = part.Split('=');
                if (kvp.Length == 2 && kvp[0].Equals("scope", StringComparison.OrdinalIgnoreCase))
                {
                    newScope = kvp[1];
                }
            }
            
            bool contextChanged = _tenantContext.AssociationId != _lastAssociationId;

            if (newScope != Scope || contextChanged)
            {
                Scope = newScope;
                ResetState();
                return true;
            }
            return false;
        }

        public void ResetState()
        {
            RecentPayments = null;
            ExistingBatches = null;
            AdvanceBalance = 0;
            NotifyStateChanged();
        }

        public async Task InitializeAsync()
        {
            try 
            {
                RecentPayments = null; // Restart spinner
                NotifyStateChanged();

                _lastAssociationId = _tenantContext.AssociationId;
                int associationId = _tenantContext.AssociationId;
                
                string overviewUrl = "api/finance/overview";
                if (Scope == "association" && associationId != 0)
                {
                    overviewUrl += $"?associationId={associationId}";
                }

                var overview = await _api.GetAsync<BillingOverview>(overviewUrl);
                if (overview != null)
                {
                    RecentPayments = overview.RecentPayments;
                    AdvanceBalance = overview.AdvanceBalance;
                    ExistingBatches = overview.ExistingBatches;

                    // Ensure batch request is tied to current association
                    BatchRequest.AssociationId = associationId;

                    // Auto-select first available month
                    if (ExistingBatches != null && ExistingBatches.Any(b => b.Month == BatchRequest.Month && b.Year == BatchRequest.Year))
                    {
                        for (int m = 1; m <= 12; m++)
                        {
                            if (!ExistingBatches.Any(b => b.Month == m && b.Year == BatchRequest.Year))
                            {
                                BatchRequest.Month = m;
                                break;
                            }
                        }
                    }
                }
                
                NotifyStateChanged();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading billing overview: {ex.Message}");
                RecentPayments = new List<Payment>();
                NotifyStateChanged();
            }
        }

        public int GetAssociationId() => _tenantContext.AssociationId;

        public async Task<int> GetAssociationIdAsync() => _tenantContext.AssociationId;

        // Batch Actions
        public async Task PreviewBatchAsync()
        {
            IsProcessingBatch = true;
            NotifyStateChanged();
            try
            {
                BatchResult = await _api.PostAsync<InvoiceBatchRequest, InvoiceBatchResult>("api/finance/batches/preview", BatchRequest);
            }
            finally
            {
                IsProcessingBatch = false;
                NotifyStateChanged();
            }
        }

        public async Task CreateDraftBatchAsync()
        {
            IsProcessingBatch = true;
            NotifyStateChanged();
            try
            {
                var success = await _api.PostAsync("api/finance/batches/draft", BatchRequest);
                if (success)
                {
                    _toastService.Notify(new(ToastType.Success, "Draft batch generated successfully."));
                    BatchResult = null;
                    await InitializeAsync();
                }
            }
            finally
            {
                IsProcessingBatch = false;
                NotifyStateChanged();
            }
        }

        public async Task FinalizeBatchAsync(BillingBatch draft)
        {
            var success = await _api.PostAsync($"api/finance/batches/{draft.BillingBatchId}/finalize", new { });
            if (success)
            {
                _toastService.Notify(new(ToastType.Success, "Batch posted to ledger and invoices activated."));
                await InitializeAsync();
            }
        }

        // Invoice Actions
        public async Task<bool> DeleteInvoiceAsync(Invoice invoice)
        {
            var success = await _api.DeleteAsync($"api/finance/invoices/{invoice.InvoiceId}");
            if (success)
            {
                _toastService.Notify(new(ToastType.Warning, "Invoice deleted."));
                return true;
            }
            return false;
        }

        public async Task SaveAdjustmentAsync()
        {
            if (AdjustingInvoice == null) return;
            
            var request = new AdjustInvoiceRequest 
            { 
                InvoiceId = AdjustingInvoice.InvoiceId,
                LineItems = AdjustingLineItems 
            };

            var success = await _api.PostAsync("api/finance/invoices/adjust", request);
            if (success)
            {
                _toastService.Notify(new(ToastType.Success, "Adjustments saved successfully."));
                ShowAdjustModal = false;
                IdToAdjust = 0;
            }
            else
            {
                _toastService.Notify(new(ToastType.Danger, "Failed to save adjustments."));
            }
        }

        public async Task LoadHistoryAsync(Invoice invoice)
        {
            TargetInvoiceId = invoice.InvoiceId;
            SelectedHistoryInvoice = invoice;
            ShowTransactionHistory = true;
            HistoryLoading = true;
            NotifyStateChanged();
            try
            {
                HistoryTransactions = await _api.GetAsync<List<PaymentHistoryItem>>($"api/finance/invoices/{invoice.InvoiceId}/history");
            }
            finally
            {
                HistoryLoading = false;
                NotifyStateChanged();
            }
        }

        public async Task DownloadInvoicePdfAsync(int id)
        {
            var fileName = $"Invoice_{id}_{DateTime.UtcNow:yyyyMMdd}.pdf";
            await _api.DownloadFileAsync($"api/finance/invoices/{id}/pdf", fileName, _js);
        }

        public async Task<bool> SettleInvoiceWithAdvanceAsync(int id)
        {
            try
            {
                var success = await _api.PostAsync($"api/finance/invoices/{id}/settled-with-advance", new { });
                if (success)
                {
                    _toastService.Notify(new(ToastType.Success, $"Invoice #{id} paid successfully using advance credit!"));
                    await InitializeAsync();
                    return true;
                }
                else
                {
                    _toastService.Notify(new(ToastType.Danger, "Insufficient advance balance or invoice not allowed for settlement."));
                    return false;
                }
            }
            catch (Exception ex)
            {
                _toastService.Notify(new(ToastType.Danger, $"Error: {ex.Message}"));
                return false;
            }
        }
    }
}
