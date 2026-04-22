using AssociationManager.Data;
using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Data;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using System.Net.Http;

namespace AssociationManager.Services.Implementations;

public class FinanceService : IFinanceService
{
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ILedgerService _ledgerService;
    private readonly ITenantContext _tenantContext;
    private readonly IAssociationRepository _associationRepository;
    private readonly IOccupancyRepository _occupancyRepository;
    private readonly IFineService _fineService;
    private readonly IAssetRepository _assetRepository;
    private readonly IAuditService _auditService;
    private readonly IBillingBatchRepository _billingBatchRepository;
    private readonly IEmailTemplateService _emailTemplateService;
    private readonly ICommunicationRepository _communicationRepository;
    private readonly IPersonRepository _personRepository;
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _config;

    public FinanceService(
        IInvoiceRepository invoiceRepository, 
        IPaymentRepository paymentRepository, 
        ILedgerService ledgerService,
        ITenantContext tenantContext,
        IAssociationRepository associationRepository,
        IOccupancyRepository occupancyRepository,
        IFineService fineService,
        IAssetRepository assetRepository,
        IAuditService auditService,
        IBillingBatchRepository billingBatchRepository,
        IEmailTemplateService emailTemplateService,
        ICommunicationRepository communicationRepository,
        IPersonRepository personRepository,
        DbConnectionFactory dbConnectionFactory,
        IHttpClientFactory httpClientFactory,
        IConfiguration config)
    {
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _ledgerService = ledgerService;
        _tenantContext = tenantContext;
        _associationRepository = associationRepository;
        _occupancyRepository = occupancyRepository;
        _fineService = fineService;
        _assetRepository = assetRepository;
        _auditService = auditService;
        _billingBatchRepository = billingBatchRepository;
        _emailTemplateService = emailTemplateService;
        _communicationRepository = communicationRepository;
        _personRepository = personRepository;
        _dbConnectionFactory = dbConnectionFactory;
        _httpClientFactory = httpClientFactory;
        _config = config;
    }

    private int CurrentTenantId => _tenantContext.TenantId;
    private int CurrentAssociationId => _tenantContext.AssociationId;

    public async Task<Invoice?> GetInvoiceByIdAsync(int id, int? associationId = null)
    {
        var invoice = await _invoiceRepository.GetByIdAsync(id, CurrentTenantId, associationId ?? CurrentAssociationId);
        if (invoice != null)
        {
            invoice.LineItems = (await _invoiceRepository.GetLineItemsAsync(id)).ToList();
            await AddFinePreviewAsync(invoice);
        }
        return invoice;
    }

    public async Task<IEnumerable<Invoice>> GetAllInvoicesAsync(int? associationId = null)
    {
        var aid = associationId ?? CurrentAssociationId;
        var invoices = await _invoiceRepository.GetAllAsync(CurrentTenantId, aid);
        var settings = await _fineService.GetSettingsAsync(aid);
        
        foreach (var inv in invoices)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
            await AddFinePreviewAsync(inv, settings);
        }
        return invoices;
    }

    public async Task<IEnumerable<Invoice>> GetInvoicesByAssetIdAsync(int assetId, int? associationId = null)
    {
        var aid = associationId ?? CurrentAssociationId;
        var invoices = await _invoiceRepository.GetByAssetIdAsync(assetId, CurrentTenantId, aid);
        var settings = await _fineService.GetSettingsAsync(aid);

        foreach (var inv in invoices)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
            await AddFinePreviewAsync(inv, settings);
        }
        return invoices;
    }

    public async Task<PagedResult<Invoice>> GetPagedInvoicesAsync(InvoiceSearchCriteria criteria)
    {
        if (criteria.AssociationId == null) criteria.AssociationId = CurrentAssociationId;
        var paged = await _invoiceRepository.GetPagedAsync(CurrentTenantId, criteria);
        var settings = await _fineService.GetSettingsAsync(criteria.AssociationId.Value);

        foreach (var inv in paged.Items)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
            await AddFinePreviewAsync(inv, settings);
        }
        return paged;
    }

    private async Task AddFinePreviewAsync(Invoice invoice, FineSettings? settings = null)
    {
        if (invoice.Status != "Paid" && invoice.DueDate < DateTime.UtcNow)
        {
            var fine = await _fineService.CalculateFineAsync(invoice, DateTime.UtcNow, settings);
            if (fine > 0)
            {
                // Check if fine is already in line items (to avoid duplication if already persisted)
                if (!invoice.LineItems.Any(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")))
                {
                    invoice.LineItems.Add(new InvoiceLineItem 
                    { 
                        ChargeName = "Late Penalty (Automated)", 
                        Amount = fine, 
                        Description = "Calculated based on association fine rules." 
                    });
                }
            }
        }
    }

    public async Task<FinanceSummary> GetFinanceSummaryAsync(int? associationId = null, int? assetId = null, IEnumerable<int>? assetIds = null, int? userId = null)
    {
        // 1. Calculate REAL unpaid balance and 30-day collection stats
        // UNIFIED FETCH: Use optimized repository stats which include penalty calculations in SQL
        var (totalUnpaid, collected) = await _invoiceRepository.GetSummaryStatsAsync(CurrentTenantId, associationId ?? CurrentAssociationId, assetId, assetIds);
        
        // 2. Resolve Wallet Balance (Credits)
        decimal totalWallet = 0;
        if (userId.HasValue)
        {
            totalWallet = await _paymentRepository.GetPersonalWalletBalanceAsync(CurrentTenantId, associationId ?? CurrentAssociationId, userId.Value);
        }
        else
        {
            var ids = assetId.HasValue ? new[] { assetId.Value } : (assetIds ?? Enumerable.Empty<int>());
            if (!ids.Any() && (associationId.HasValue || CurrentAssociationId != 0))
            {
                // ASSOCIATION-WIDE FETCH: Uses optimized sp_Finance_GetAssociationSummary
                var baseStats = await _invoiceRepository.GetAssociationSummaryAsync(associationId ?? CurrentAssociationId, CurrentTenantId);
                totalWallet = baseStats.TotalCredits;
            }
            else
            {
                // Mapped Asset Fetch (Fallback for specific lists)
                foreach (var aid in ids)
                {
                    totalWallet += await GetAssetWalletBalanceAsync(aid);
                }
            }
        }
        
        return new FinanceSummary 
        { 
            TotalUnpaid = totalUnpaid, 
            Collected30Days = collected,
            TotalAdvanceCredits = totalWallet
        };
    }


    public async Task<int> CreateInvoiceAsync(Invoice invoice, IEnumerable<InvoiceLineItem>? lineItems = null)
    {
        invoice.TenantId = CurrentTenantId;
        invoice.AssociationId = CurrentAssociationId;
        var id = await _invoiceRepository.CreateAsync(invoice);

        // Save Line Items if any
        if (lineItems != null)
        {
            foreach (var item in lineItems)
            {
                item.InvoiceId = id;
                await _invoiceRepository.CreateLineItemAsync(item);
            }
        }

        // Record Ledger Entry (Debit) via LedgerService
        // ONLY if the invoice is NOT a Draft
        if (invoice.AssetId.HasValue && invoice.Status != "Draft")
        {
            await _ledgerService.RecordTransactionAsync(new Transaction
            {
                AssetId = invoice.AssetId.Value,
                InvoiceId = id,
                Type = "Debit",
                Amount = invoice.Amount,
                Category = "Billing",
                Description = $"Invoice Generated: {invoice.Title}"
            });

            /* AUTO-SETTLE DISABLED: Requirement to allow manual settlement only
            await AutoSettleInvoicesAsync(invoice.AssetId.Value); 
            */
        }

        return id;
    }

    public async Task<bool> UpdateInvoiceStatusAsync(int id, string status, int? associationId = null)
    {
        return await _invoiceRepository.UpdateStatusAsync(id, status, CurrentTenantId, associationId ?? CurrentAssociationId);
    }

    public async Task<bool> DeleteInvoiceAsync(int id, int? associationId = null)
    {
        return await _invoiceRepository.DeleteAsync(id, CurrentTenantId, associationId ?? CurrentAssociationId);
    }

    public async Task<IEnumerable<Payment>> GetPaymentsAsync(int? associationId = null, IEnumerable<int>? assetIds = null)
    {
        var payments = await _paymentRepository.GetByTenantIdAsync(CurrentTenantId, associationId ?? CurrentAssociationId);
        
        if (assetIds != null && assetIds.Any())
        {
            return payments.Where(p => p.AssetId.HasValue && assetIds.Contains(p.AssetId.Value));
        }
        
        return payments;
    }

    public async Task<IEnumerable<Payment>> GetRecentPaymentsAsync(int? associationId = null, int count = 20, IEnumerable<int>? assetIds = null)
    {
        return await _paymentRepository.GetRecentByAssociationIdAsync(CurrentTenantId, associationId ?? CurrentAssociationId, count, assetIds);
    }

    public async Task<int> CreatePaymentAsync(Payment payment)
    {
        payment.TenantId = CurrentTenantId;
        payment.AssociationId = CurrentAssociationId;
        payment.UserId = _tenantContext.UserId;
        
        var id = await _paymentRepository.CreateAsync(payment);

        // Record Ledger Entry (Credit) via LedgerService
        if (payment.AssetId.HasValue)
        {
            await _ledgerService.RecordTransactionAsync(new Transaction
            {
                AssetId = payment.AssetId.Value,
                PaymentId = id,
                InvoiceId = payment.InvoiceId,
                Type = "Credit",
                Amount = payment.Amount,
                Category = "Payment",
                Description = payment.Notes ?? (payment.InvoiceId.HasValue ? "Invoice Payment" : "Advance Payment")
            });

            /* AUTO-SETTLE DISABLED
            if (!payment.InvoiceId.HasValue)
            {
                await AutoSettleInvoicesAsync(payment.AssetId.Value);
            }
            */
        }
        else if (payment.UserId != 0)
        {
            // GLOBAL SETTLEMENT: Distribute payment across all assets owned by this user
            var assets = await _occupancyRepository.GetByUserIdAsync(payment.UserId, CurrentTenantId, CurrentAssociationId);
            var remainingAmount = payment.Amount;

            foreach (var occupancy in assets)
            {
                if (remainingAmount <= 0) break;

                var balance = await GetAssetBalanceAsync(occupancy.AssetId);
                if (balance > 0) // Asset has outstanding balance
                {
                    var attribution = Math.Min(balance, remainingAmount);
                    await _ledgerService.RecordTransactionAsync(new Transaction
                    {
                        AssetId = occupancy.AssetId,
                        PaymentId = id,
                        Type = "Credit",
                        Amount = attribution,
                        Category = "Payment",
                        Description = "Global Balance Settlement"
                    });

                    remainingAmount -= attribution;
                    // await AutoSettleInvoicesAsync(occupancy.AssetId); // AUTO-SETTLE DISABLED
                }
            }

            // If there's still a surplus, put it into the first asset as advance credit
            if (remainingAmount > 0)
            {
                var firstAsset = assets.FirstOrDefault();
                if (firstAsset != null)
                {
                    await _ledgerService.RecordTransactionAsync(new Transaction
                    {
                        AssetId = firstAsset.AssetId,
                        PaymentId = id,
                        Type = "Credit",
                        Amount = remainingAmount,
                        Category = "Payment",
                        Description = "Consolidated Advance Payment (Surplus)"
                    });
                }
            }
        }

        // If Payment is linked to an Invoice, update invoice status
        if (payment.InvoiceId.HasValue)
        {
            // PERSIST FINE: Convert the virtual preview fine into a permanent DB record before marking as Paid
            var invoice = await GetInvoiceByIdAsync(payment.InvoiceId.Value, payment.AssociationId);
            if (invoice != null && invoice.Status != "Paid")
            {
                // Find the virtual fine item (ID == 0) that was added by the preview logic
                var virtualFine = invoice.LineItems.FirstOrDefault(l => l.InvoiceLineItemId == 0 && 
                                   (l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")));
                
                if (virtualFine != null)
                {
                    virtualFine.InvoiceId = invoice.InvoiceId; // Ensure correct ID
                    await _invoiceRepository.CreateLineItemAsync(virtualFine);
                    
                    // Optional: Update the ledger transaction amount to include the fine for audit clarity
                    // But usually, the Payment amount already covers it.
                }
            }

            await _invoiceRepository.UpdateStatusAsync(payment.InvoiceId.Value, "Paid", CurrentTenantId, CurrentAssociationId);
        }

        return id;
    }

    public async Task<IEnumerable<Transaction>> GetAssetTransactionsAsync(int assetId)
    {
        return await _ledgerService.GetAssetTransactionsAsync(assetId);
    }

    public async Task<decimal> GetAssetBalanceAsync(int assetId)
    {
        var invoices = await GetInvoicesByAssetIdAsync(assetId);
        decimal outstanding = 0;
        foreach (var inv in invoices.Where(i => i.Status != "Paid"))
        {
            outstanding += await GetTotalInvoiceAmountAsync(inv);
        }
        return outstanding;
    }

    public async Task<bool> AutoSettleInvoicesAsync(int assetId, int? associationId = null)
    {
        // USER REQ: Persist fines before auto-settling.
        // We fetch all pending invoices, calculate/persist fine if needed.
        var invoices = await GetInvoicesByAssetIdAsync(assetId, associationId);
        foreach (var inv in invoices.Where(i => i.Status != "Paid"))
        {
            var fine = await _fineService.CalculateFineAsync(inv, DateTime.UtcNow);
            if (fine > 0)
            {
                // Only persist if not already persisted
                var existingLineItems = await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId);
                if (!existingLineItems.Any(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")))
                {
                    await _invoiceRepository.CreateLineItemAsync(new InvoiceLineItem 
                    { 
                        InvoiceId = inv.InvoiceId,
                        ChargeName = "Late Penalty (Automated)",
                        Amount = fine,
                        Description = "Calculated at settlement based on association fine rules."
                    });
                }
            }
        }

        return await _paymentRepository.AutoSettleAsync(assetId, CurrentTenantId, associationId ?? CurrentAssociationId, _tenantContext.UserId);
    }

    public async Task<bool> AutoSettleUserInvoicesAsync(int userId, int? associationId = null)
    {
        var assets = await _occupancyRepository.GetByUserIdAsync(userId, CurrentTenantId, associationId ?? CurrentAssociationId);
        foreach (var occupancy in assets)
        {
            await AutoSettleInvoicesAsync(occupancy.AssetId, associationId);
        }
        return true;
    }

    public async Task<bool> SettleInvoiceWithAdvanceAsync(int invoiceId)
    {
        var invoice = await GetInvoiceByIdAsync(invoiceId);
        if (invoice == null || !invoice.AssetId.HasValue || invoice.Status == "Paid") return false;

        // Support Cross-Asset Settlement: Find all assets for this resident
        var userAssets = (await _occupancyRepository.GetByUserIdAsync(_tenantContext.UserId, CurrentTenantId, CurrentAssociationId)).ToList();
        
        // 1. Calculate Gross Wallet Power across ALL user assets
        // Gross Wallet = (Sum of Payments/Advances) - (Sum of Credit Settlements)
        decimal totalWalletPower = 0;
        foreach (var asset in userAssets)
        {
            totalWalletPower += await GetAssetWalletBalanceAsync(asset.AssetId);
        }

        if (totalWalletPower <= 0) return false;
        
        // UNIFIED TOTAL: Use the shared calculation logic to determine the exact amount due.
        decimal totalAmountDue = await GetTotalInvoiceAmountAsync(invoice);
        
        if (totalWalletPower < totalAmountDue) return false;

        decimal remainingSettleAmount = totalAmountDue;
        decimal spendableWallet = totalWalletPower;

        foreach (var asset in userAssets)
        {
            if (remainingSettleAmount <= 0 || spendableWallet <= 0) break;

            // How much of the wallet power is stored specifically in this asset?
            var assetWalletPower = await GetAssetWalletBalanceAsync(asset.AssetId);

            if (assetWalletPower > 0)
            {
                var attribution = Math.Min(Math.Min(assetWalletPower, remainingSettleAmount), spendableWallet);

                if (attribution > 0)
                {
                    // Record SETTLEMENT (Debit to the Wallet)
                    await _ledgerService.RecordTransactionAsync(new Transaction
                    {
                        AssetId = asset.AssetId,
                        Type = "Debit",
                        Amount = attribution,
                        Category = "Credit Settlement",
                        Description = $"Advance used to pay Invoice #{invoiceId}"
                    });

                    // Record PAYMENT (Credit to the Invoice)
                    await _ledgerService.RecordTransactionAsync(new Transaction
                    {
                        AssetId = invoice.AssetId.Value,
                        InvoiceId = invoiceId,
                        Type = "Credit",
                        Amount = attribution,
                        Category = "Credit Settlement",
                        Description = asset.AssetId == invoice.AssetId.Value 
                            ? "Settled via Advance Credit" 
                            : $"Settled via Credit Transfer from Unit #{asset.AssetId}"
                    });

                    remainingSettleAmount -= attribution;
                    spendableWallet -= attribution;
                }
            }
        }

        if (remainingSettleAmount <= 0)
        {
            // PERSIST FINE: Convert the virtual preview fine into a permanent DB record before marking as Paid
            // We search for any line item with ID 0 that contains Fine/Penalty keywords
            var virtualFine = invoice.LineItems.FirstOrDefault(l => l.InvoiceLineItemId == 0 && 
                               (l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")));
            
            if (virtualFine != null)
            {
                virtualFine.InvoiceId = invoice.InvoiceId;
                await _invoiceRepository.CreateLineItemAsync(virtualFine);
            }

            await _invoiceRepository.UpdateStatusAsync(invoiceId, "Paid", CurrentTenantId, invoice.AssociationId, isAdvancePaid: true);
            
            // Trigger Real-time Dashboard Sync to update Net Outstanding metrics immediately
            _ = Task.Run(() => SyncAssociationBalancesAsync(invoice.AssociationId, CurrentTenantId));
            
            return true;
        }

        return remainingSettleAmount < totalAmountDue;
    }

    public async Task<IEnumerable<Transaction>> GetTenantTransactionsAsync(DateTime? start = null, DateTime? end = null)
    {
        return await _ledgerService.GetTenantTransactionsAsync(start, end);
    }

    public async Task<AssociationBankDetails?> GetBankDetailsAsync(int associationId)
    {
        return await _associationRepository.GetBankDetailsAsync(associationId, CurrentTenantId);
    }

    public async Task<bool> UpdateBankDetailsAsync(AssociationBankDetails details)
    {
        details.TenantId = CurrentTenantId;
        return await _associationRepository.UpsertBankDetailsAsync(details);
    }

    public async Task<(decimal TotalOutstanding, decimal TotalCredits, int UnitsWithCredit)> GetAssociationFinanceSummaryAsync(int associationId, int tenantId)
    {
        // OPTIMIZED: Single call to the snapshot SP which returns all three values.
        // sp_Finance_GetAssociationSummary_Snapshot reads from AssociationBalances cache table (fast path)
        // and only falls back to live calculation when no snapshot exists.
        var baseStats = await _invoiceRepository.GetAssociationSummaryAsync(associationId, tenantId);
        
        return (baseStats.TotalOutstanding, baseStats.TotalCredits, baseStats.UnitsWithCredit);
    }

    public async Task<IEnumerable<AdvancePaymentHistory>> GetAdvancesAsync(int associationId, int tenantId, int? userId = null, int? assetId = null)
    {
        return await _paymentRepository.GetAdvancesAsync(tenantId, associationId, userId, assetId);
    }

    public async Task<bool> SyncAssociationBalancesAsync(int associationId, int tenantId)
    {
        return await _ledgerService.SyncAssociationBalancesAsync(associationId, tenantId);
    }

    public async Task<PagedResult<AdvancePaymentHistory>> GetPagedAdvancesAsync(AdvanceSearchCriteria criteria)
    {
        if (criteria.TenantId == null) criteria.TenantId = CurrentTenantId;
        if (criteria.AssociationId == null) criteria.AssociationId = CurrentAssociationId;
        return await _paymentRepository.GetAdvancesPagedAsync(criteria);
    }

    /// <summary>
    /// Unified calculation logic for Total Invoice Amount.
    /// Ensures that Amount (Principal) and Breakdown (Line Items) are not double-counted.
    /// Logic: Sum of LineItems (if they exist), or Invoice.Amount if no line items are found.
    /// It effectively handles virtual fines (preview) and persisted fines identically.
    /// </summary>
    private async Task<decimal> GetTotalInvoiceAmountAsync(Invoice invoice)
    {
        // 1. If no line items, return the base amount
        if (invoice.LineItems == null || !invoice.LineItems.Any()) 
            return invoice.Amount;

        // 2. Extract specific charges
        decimal principalLineItems = invoice.LineItems.Where(l => !l.ChargeName.Contains("Penalty") && !l.ChargeName.Contains("Fine")).Sum(l => l.Amount);
        decimal penaltyLineItems = invoice.LineItems.Where(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine")).Sum(l => l.Amount);

        // 3. UNIFIED RULE: The "True Principal" is the maximum of the invoice.Amount or the sum of principal breakdown line items.
        // This prevents double-counting if Amount is 200 and a 'Maintenance Fee' line item is also 200.
        decimal truePrincipal = Math.Max(invoice.Amount, principalLineItems);

        return truePrincipal + penaltyLineItems;
    }

    /// <summary>
    /// Robust calculation of the wallet balance for a specific asset.
    /// It considers Credits (Advances/Payments) and Debits (Settlements) while handling
    /// case-sensitivity and potential 0 vs null InvoiceId edge cases from the database.
    /// </summary>
    private async Task<decimal> GetAssetWalletBalanceAsync(int assetId)
    {
        var txs = await GetAssetTransactionsAsync(assetId);
        
        // ROBUST CALCULATION: Case-insensitive and handling potential 0 vs null InvoiceId
        var advances = txs.Where(t => 
            string.Equals(t.Type, "Credit", StringComparison.OrdinalIgnoreCase) && 
            (string.Equals(t.Category, "Payment", StringComparison.OrdinalIgnoreCase) || 
             string.Equals(t.Category, "Advance Payment", StringComparison.OrdinalIgnoreCase)) && 
            (!t.InvoiceId.HasValue || t.InvoiceId == 0)
        ).Sum(t => t.Amount);

        var settlements = txs.Where(t => 
            string.Equals(t.Type, "Debit", StringComparison.OrdinalIgnoreCase) && 
            (string.Equals(t.Category, "Credit Settlement", StringComparison.OrdinalIgnoreCase) || 
             string.Equals(t.Category, "Internal Credit Transfer", StringComparison.OrdinalIgnoreCase))
        ).Sum(t => t.Amount);

        return (advances - settlements);
    }
    public async Task<int> PostOverdueFinesAsync()
    {
        var invoices = (await _invoiceRepository.GetUnpaidOverdueInvoicesAsync())
            .Where(i => i.AssociationId != 0)
            .ToList();
        
        if (!invoices.Any()) return 0;

        int totalPostedCount = 0;
        var now = DateTime.UtcNow;

        // Grouping to log a summary per association
        var associationSummary = new Dictionary<int, (int TenantId, int Count)>();

        foreach (var invoice in invoices)
        {
            // Calculate Total Accumulated Fine
            var totalFineCalculated = await _fineService.CalculateFineAsync(invoice, now);
            if (totalFineCalculated <= 0) continue;

            // Get Already Posted Fines
            var lineItems = await _invoiceRepository.GetLineItemsAsync(invoice.InvoiceId);
            var totalFinePosted = lineItems
                .Where(l => l.ChargeName.Contains("Penalty") || l.ChargeName.Contains("Fine"))
                .Sum(l => l.Amount);

            var delta = totalFineCalculated - totalFinePosted;

            if (delta >= 0.01m)
            {
                var fineLineItem = new InvoiceLineItem
                {
                    InvoiceId = invoice.InvoiceId,
                    ChargeName = $"Late Penalty (Automated) - {now:MMM yyyy}",
                    Amount = delta,
                    Description = $"Automated monthly penalty posting for {invoice.Title}."
                };

                await _invoiceRepository.CreateLineItemAsync(fineLineItem);

                if (invoice.AssetId.HasValue)
                {
                    await _ledgerService.RecordTransactionAsync(new Transaction
                    {
                        AssetId = invoice.AssetId.Value,
                        InvoiceId = invoice.InvoiceId,
                        TenantId = invoice.TenantId,
                        AssociationId = invoice.AssociationId,
                        Type = "Debit",
                        Amount = delta,
                        Category = "Penalty",
                        Description = $"Late Penalty Posted: {invoice.Title}"
                    });
                }

                // Update summary for auditing
                if (!associationSummary.ContainsKey(invoice.AssociationId))
                {
                    associationSummary[invoice.AssociationId] = (invoice.TenantId, 1);
                }
                else
                {
                    var existing = associationSummary[invoice.AssociationId];
                    associationSummary[invoice.AssociationId] = (existing.TenantId, existing.Count + 1);
                }
                
                totalPostedCount++;
            }
        }

        // Log summaries per association
        foreach (var entry in associationSummary)
        {
            await _auditService.LogAsync(
                action: $"Automated Fine Posting Batch: {entry.Value.Count} invoices",
                entity: "Association",
                entityId: entry.Key,
                associationId: entry.Key,
                tenantId: entry.Value.TenantId
            );
        }

        // Final global summary if any work was done
        if (totalPostedCount > 0)
        {
            var fallbackTenantId = associationSummary.Values.FirstOrDefault().TenantId;
            await _auditService.LogAsync(
                action: $"Automated Fine Posting Run: Total {totalPostedCount} fines",
                entity: "Automation",
                tenantId: fallbackTenantId
            );
        }

        return totalPostedCount;
    }

    public async Task<bool> DeleteBatchAsync(int batchId, int? associationId = null)
    {
        var aid = associationId ?? CurrentAssociationId;
        var batch = await _billingBatchRepository.GetByIdAsync(batchId, CurrentTenantId, aid);
        
        if (batch == null) return false;
        
        // Safety: Only Draft, Failed, or inconsistent (with draft invoices) batches can be deleted
        if (batch.Status != "Draft" && batch.Status != "COMMIT_FAILED" && !batch.HasDraftInvoices)
        {
            throw new InvalidOperationException("Only Draft, Failed, or incomplete batches can be deleted.");
        }

        return await _billingBatchRepository.DeleteBatchAsync(batchId, CurrentTenantId, aid);
    }

    public async Task<bool> CommitBatchAsync(int batchId, int tenantId = 0, int associationId = 0)
    {
        if (tenantId > 0 && _tenantContext is AssociationManager.Services.Implementations.BackgroundTenantContext bgContext)
        {
            bgContext.SetContext(tenantId, associationId);
        }

        try
        {
            var batch = await _billingBatchRepository.GetByIdAsync(batchId, CurrentTenantId, CurrentAssociationId);
            if (batch == null || (batch.Status != "Draft" && batch.Status != "Committed")) return false;

            // 1. High-Performance Bulk Commit (Status + Ledger + Sync)
            var success = await _billingBatchRepository.BulkCommitAsync(batchId, CurrentTenantId, CurrentAssociationId);
            
            if (success)
            {
                // 2. Offload Emails to Background Queue (Non-Blocking)
                Hangfire.BackgroundJob.Enqueue<IFinanceService>(x => x.EnqueueBatchNotificationsAsync(batchId, CurrentTenantId, CurrentAssociationId));

                // 3. Notify UI of Success
                await NotifyCommitStatusAsync(batchId, CurrentTenantId, CurrentAssociationId, "COMMIT_READY");
            }
            else
            {
                await NotifyCommitStatusAsync(batchId, CurrentTenantId, CurrentAssociationId, "COMMIT_FAILED");
            }

            return success;
        }
        catch (Exception ex)
        {
            // Log the error
            await _auditService.LogAsync($"Batch Commitment Error: {ex.Message}", "BillingBatch", batchId, associationId: associationId, tenantId: tenantId);
            
            // Notify UI of Failure
            await NotifyCommitStatusAsync(batchId, tenantId, associationId, "COMMIT_FAILED");
            
            throw; // Re-throw for Hangfire retry
        }
    }

    public async Task NotifyCommitStatusAsync(int batchId, int tenantId, int associationId, string status)
    {
        try
        {
            var baseUrl = _config["ApiSettings:GatewayUrl"];
            if (string.IsNullOrEmpty(baseUrl)) return;

            var client = _httpClientFactory.CreateClient();
            var url = $"{baseUrl.TrimEnd('/')}/api/finance/batches/notify-completion?tenantId={tenantId}&associationId={associationId}&period=batch-{batchId}&jobId=commit-{batchId}&status={status}";
            
            Console.WriteLine($"[Diagnostic] Notifying UI of Commit Status: {url}");
            await client.PostAsync(url, null);
        }
        catch (Exception ex)
        {
             Console.WriteLine($"[Diagnostic] Commit Notification Exception: {ex.Message}");
             await _auditService.LogAsync($"Failed to notify UI of commit completion: {ex.Message}", "System", 0, associationId: associationId, tenantId: tenantId);
        }
    }

    public async Task EnqueueBatchNotificationsAsync(int batchId, int tenantId, int associationId)
    {
         if (tenantId > 0 && _tenantContext is AssociationManager.Services.Implementations.BackgroundTenantContext bgContext)
        {
            bgContext.SetContext(tenantId, associationId);
        }

        var invoices = await _invoiceRepository.GetByBatchIdAsync(batchId, CurrentTenantId);
        foreach (var inv in invoices)
        {
            // Only notify if Unpaid (which they should be now after BulkCommit)
            if (inv.Status == "Unpaid" && inv.AssetId.HasValue)
            {
                // Enqueue each individual email as its own job for maximum reliability
                Hangfire.BackgroundJob.Enqueue<IFinanceService>(x => x.SendInvoiceNotificationAsync(inv.InvoiceId, tenantId, associationId));
            }
        }
    }

    // New helper for Hangfire to send a single resident notification
    public async Task SendInvoiceNotificationAsync(int invoiceId, int tenantId, int associationId)
    {
         if (tenantId > 0 && _tenantContext is AssociationManager.Services.Implementations.BackgroundTenantContext bgContext)
        {
            bgContext.SetContext(tenantId, associationId);
        }

        var inv = await _invoiceRepository.GetByIdAsync(invoiceId, CurrentTenantId, CurrentAssociationId);
        if (inv == null || !inv.AssetId.HasValue) return;

        var occupancies = await _occupancyRepository.GetByAssetIdAsync(inv.AssetId.Value, CurrentTenantId, CurrentAssociationId);
        var primary = occupancies.FirstOrDefault(o => o.IsPrimaryContact) ?? occupancies.FirstOrDefault();
        
        if (primary != null)
        {
            var person = await _personRepository.GetByIdAsync(primary.PersonId, CurrentTenantId, CurrentAssociationId);
            if (person != null && !string.IsNullOrEmpty(person.Email))
            {
                var htmlBody = await _emailTemplateService.GenerateInvoiceHtmlAsync(inv.InvoiceId);
                
                await _communicationRepository.CreateAsync(new CommunicationLog
                {
                    TenantId = CurrentTenantId,
                    AssociationId = CurrentAssociationId,
                    RecipientEmail = person.Email,
                    RecipientName = $"{person.FirstName} {person.LastName}",
                    Subject = $"Invoice Generated: {inv.Title} (Ref #{inv.InvoiceId})",
                    HtmlBody = htmlBody,
                    ReferenceType = "Invoice",
                    ReferenceId = inv.InvoiceId,
                    Status = AssociationManager.Shared.Enums.CommunicationStatus.Posted
                });
            }
        }
    }

    public async Task<bool> AdjustInvoiceLineItemsAsync(int invoiceId, IEnumerable<InvoiceLineItem> items)
    {
        var invoice = await GetInvoiceByIdAsync(invoiceId);
        if (invoice == null || invoice.Status != "Draft") return false;

        // 1. Clear existing line items
        // (Assuming we have a DeleteLineItemsByInvoiceId or we just create a new list)
        // For simplicity, we can implement a Sync method in Repository or just loop.
        // Let's assume we need to handle this via Repository.
        
        // Actually, let's just implement the logic:
        await _invoiceRepository.DeleteAllLineItemsAsync(invoiceId);

        decimal newTotal = 0;
        foreach (var item in items)
        {
            item.InvoiceId = invoiceId;
            await _invoiceRepository.CreateLineItemAsync(item);
            newTotal += item.Amount;
        }

        // 2. Update Invoice Amount
        invoice.Amount = newTotal;
        await _invoiceRepository.UpdateAsync(invoice);

        await _auditService.LogAsync($"Adjusted Draft Invoice #{invoiceId} Line Items", "Invoice", invoiceId, assetId: invoice.AssetId);
        return true;
    }

    public async Task<IEnumerable<PaymentHistoryItem>> GetInvoicePaymentHistoryAsync(int invoiceId)
    {
        var history = new List<PaymentHistoryItem>();

        // 1. Fetch Ledger Transactions (Settlements)
        var transactions = await _ledgerService.GetTransactionsByInvoiceIdAsync(invoiceId);
        foreach (var tx in transactions.Where(t => t.Type == "Credit" && t.Category == "Credit Settlement"))
        {
            history.Add(new PaymentHistoryItem
            {
                CreatedDate = tx.TransactionDate,
                Amount = tx.Amount,
                Status = "Success",
                ReferenceId = $"SETTLE-{tx.TransactionId}",
                PaymentMethod = "Advance Credit",
                Method = "Internal"
            });
        }

        // 2. Fetch Gateway Payments
        // We use a broader fetch because we don't have a specific GetByInvoiceId in PaymentRepository yet, 
        // but we can filter the association's payments for efficiency.
        var associationId = _tenantContext.AssociationId;
        var allPayments = await _paymentRepository.GetByTenantIdAsync(_tenantContext.TenantId, associationId);
        var invoicePayments = allPayments.Where(p => p.InvoiceId == invoiceId);

        foreach (var p in invoicePayments)
        {
            history.Add(new PaymentHistoryItem
            {
                CreatedDate = p.CreatedDate,
                Amount = p.Amount,
                Status = p.Status,
                ReferenceId = p.GatewayReference ?? $"PAY-{p.PaymentId}",
                PaymentMethod = "Razorpay",
                Method = "Card/UPI/NetBanking"
            });
        }

        return history.OrderByDescending(h => h.CreatedDate);
    }
}
