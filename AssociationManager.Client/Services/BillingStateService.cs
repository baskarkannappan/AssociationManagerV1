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
        private readonly RealtimeService _realtime;
        private int _lastAssociationId;

        public BillingStateService(
            ApiService api, 
            AuthenticationStateProvider authStateProvider, 
            NavigationManager navigation,
            ToastService toastService,
            IJSRuntime js,
            ITenantContext tenantContext,
            RealtimeService realtime)
        {
            _api = api;
            _authStateProvider = authStateProvider;
            _navigation = navigation;
            _toastService = toastService;
            _js = js;
            _tenantContext = tenantContext;
            _realtime = realtime;
            _realtime.OnBatchCompleted += HandleBatchCompleted;
            
            ParseQueryParameters();
        }

        private async void HandleBatchCompleted(int associationId, string period, string? jobId = null, string? status = "BATCH_READY")
        {
            if (associationId == _tenantContext.AssociationId)
            {
                if (status == "PREVIEW_READY" && !string.IsNullOrEmpty(jobId))
                {
                    await FetchPreviewResultAsync(jobId);
                }
                else if (status == "COMMIT_READY")
                {
                    _toastService.Notify(new(ToastType.Success, "Batch successfully posted to ledger and invoices activated!"));
                    await InitializeAsync();
                }
                else if (status == "COMMIT_FAILED")
                {
                    _toastService.Notify(new(ToastType.Danger, "Ledger commitment failed due to a system deadlock. The system is retrying, or you can try again later.", "Database Conflict"));
                    await InitializeAsync();
                }
                else
                {
                    GeneratingBatchReference = null;
                    _toastService.Notify(new(ToastType.Success, $"Batch generation for {period} completed in the background."));
                    await InitializeAsync();
                }
                
                NotifyStateChanged();
            }
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
        
        public (int Month, int Year)? GeneratingBatchReference { get; private set; }
        public bool IsGeneratingBatch => GeneratingBatchReference != null;

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

        private bool _showManualPaymentModal;
        public bool ShowManualPaymentModal
        {
            get => _showManualPaymentModal;
            set { _showManualPaymentModal = value; NotifyStateChanged(); }
        }
        
        public int TargetInvoiceId { get; set; }
        public Invoice? SelectedHistoryInvoice { get; set; }
        public Invoice? ManualPaymentInvoice { get; set; }
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
                    
                    // Defensive check: If we are "generating" but the batch is already here, reset the flag
                    if (GeneratingBatchReference != null && ExistingBatches != null && ExistingBatches.Any(b => b.Month == GeneratingBatchReference.Value.Month && b.Year == GeneratingBatchReference.Value.Year && b.Status == "Draft"))
                    {
                        GeneratingBatchReference = null;
                    }

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
        public async Task DeleteBatchAsync(BillingBatch draft)
        {
            try
            {
                var success = await _api.DeleteAsync($"api/finance/batches/{draft.BillingBatchId}");
                if (success)
                {
                    _toastService.Notify(new(ToastType.Warning, $"Draft batch for {System.Globalization.DateTimeFormatInfo.CurrentInfo.GetMonthName(draft.Month)} {draft.Year} has been deleted."));
                    await InitializeAsync();
                }
                else
                {
                    _toastService.Notify(new(ToastType.Danger, "Failed to delete batch."));
                }
            }
            catch (Exception ex)
            {
                _toastService.Notify(new(ToastType.Danger, $"Error: {ex.Message}"));
            }
        }

        public async Task PreviewBatchAsync()
        {
            IsProcessingBatch = true;
            BatchResult = null;
            NotifyStateChanged();
            try
            {
                var response = await _api.PostAsync<InvoiceBatchRequest, string>("api/finance/batches/preview", BatchRequest);
                if (!string.IsNullOrEmpty(response))
                {
                    _toastService.Notify(new(ToastType.Info, "Preview calculation started in the background...", "Scaling Optimization"));
                    
                    // Poll for the result every 5 seconds (up to 3 minutes)
                    _ = PollForPreviewAsync(response);
                }
                else
                {
                    IsProcessingBatch = false;
                }
            }
            catch (Exception ex)
            {
                _toastService.Notify(new(ToastType.Danger, $"Preview Failed: {ex.Message}"));
                IsProcessingBatch = false;
            }
            finally
            {
                NotifyStateChanged();
            }
        }

        private async Task PollForPreviewAsync(string trackingId)
        {
            const int maxAttempts = 36; // 36 x 5s = 3 minutes max
            for (int i = 0; i < maxAttempts; i++)
            {
                await Task.Delay(5000); // Wait 5 seconds between polls
                
                try
                {
                    var result = await _api.GetAsync<InvoiceBatchResult>($"api/finance/batches/preview/{trackingId}");
                    if (result != null)
                    {
                        BatchResult = result;
                        IsProcessingBatch = false;
                        _toastService.Notify(new(ToastType.Success, "Batch preview is ready for review."));
                        NotifyStateChanged();
                        return;
                    }
                }
                catch
                {
                    // Preview not ready yet, continue polling
                }
            }
            
            // Timeout
            IsProcessingBatch = false;
            _toastService.Notify(new(ToastType.Warning, "Preview generation timed out. Please try again."));
            NotifyStateChanged();
        }

        public async Task FetchPreviewResultAsync(string trackingId)
        {
            try
            {
                var result = await _api.GetAsync<InvoiceBatchResult>($"api/finance/batches/preview/{trackingId}");
                if (result != null)
                {
                    BatchResult = result;
                    _toastService.Notify(new(ToastType.Success, "Batch preview is ready for review."));
                }
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
                    _toastService.Notify(new(ToastType.Info, "Draft batch generation has been queued. Please wait ...", "Processing Background Job"));
                    BatchResult = null;
                    GeneratingBatchReference = (BatchRequest.Month, BatchRequest.Year);
                    NotifyStateChanged();
                    
                    // Poll for batch completion since SignalR may not deliver
                    _ = PollForDraftBatchAsync(GeneratingBatchReference.Value.Month, GeneratingBatchReference.Value.Year);
                }
            }
            finally
            {
                IsProcessingBatch = false;
                NotifyStateChanged();
            }
        }

        private async Task PollForDraftBatchAsync(int month, int year)
        {
            const int maxAttempts = 60; // 60 x 5s = 5 minutes max
            for (int i = 0; i < maxAttempts; i++)
            {
                await Task.Delay(5000);
                
                try
                {
                    await InitializeAsync();
                    
                    // InitializeAsync already has a defensive check that clears GeneratingBatchReference
                    // when the batch appears in ExistingBatches with Status == "Draft"
                    if (GeneratingBatchReference == null)
                    {
                        _toastService.Notify(new(ToastType.Success, $"Draft batch for {System.Globalization.DateTimeFormatInfo.CurrentInfo.GetMonthName(month)} {year} created successfully!"));
                        return;
                    }
                }
                catch
                {
                    // Continue polling on error
                }
            }
            
            // Timeout
            GeneratingBatchReference = null;
            _toastService.Notify(new(ToastType.Warning, "Batch generation timed out. Please refresh the page."));
            NotifyStateChanged();
        }

        public async Task FinalizeBatchAsync(BillingBatch draft)
        {
            _toastService.Notify(new(ToastType.Info, "Posting batch to ledger... this may take a moment for large volumes.", "Processing Ledger"));
            
            var success = await _api.PostAsync($"api/finance/batches/{draft.BillingBatchId}/finalize", new { });
            if (!success)
            {
                _toastService.Notify(new(ToastType.Danger, "Failed to initiate batch commitment. Please check your connection."));
            }
            // Note: If success, we wait for the SignalR notification (HandleBatchCompleted) to show the final success message
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

        public async Task<bool> RecordManualPaymentAsync(Payment payment)
        {
            try
            {
                var responseId = await _api.PostAsync<Payment, int>("api/finance/payments", payment);
                if (responseId > 0)
                {
                    _toastService.Notify(new(ToastType.Success, $"Manual payment recorded successfully (Ref: {payment.Notes})"));
                    ShowManualPaymentModal = false;
                    await InitializeAsync();
                    return true;
                }
                _toastService.Notify(new(ToastType.Danger, "Failed to record manual payment."));
                return false;
            }
            catch (Exception ex)
            {
                _toastService.Notify(new(ToastType.Danger, $"Error: {ex.Message}"));
                return false;
            }
        }
    }
}
