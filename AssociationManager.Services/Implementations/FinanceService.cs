using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

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

    public FinanceService(
        IInvoiceRepository invoiceRepository, 
        IPaymentRepository paymentRepository, 
        ILedgerService ledgerService,
        ITenantContext tenantContext,
        IAssociationRepository associationRepository,
        IOccupancyRepository occupancyRepository,
        IFineService fineService,
        IAssetRepository assetRepository)
    {
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _ledgerService = ledgerService;
        _tenantContext = tenantContext;
        _associationRepository = associationRepository;
        _occupancyRepository = occupancyRepository;
        _fineService = fineService;
        _assetRepository = assetRepository;
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
        var invoices = await _invoiceRepository.GetAllAsync(CurrentTenantId, associationId ?? CurrentAssociationId);
        foreach (var inv in invoices)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
            await AddFinePreviewAsync(inv);
        }
        return invoices;
    }

    public async Task<IEnumerable<Invoice>> GetInvoicesByAssetIdAsync(int assetId, int? associationId = null)
    {
        var invoices = await _invoiceRepository.GetByAssetIdAsync(assetId, CurrentTenantId, associationId ?? CurrentAssociationId);
        foreach (var inv in invoices)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
            await AddFinePreviewAsync(inv);
        }
        return invoices;
    }

    public async Task<PagedResult<Invoice>> GetPagedInvoicesAsync(InvoiceSearchCriteria criteria)
    {
        if (criteria.AssociationId == null) criteria.AssociationId = CurrentAssociationId;
        var paged = await _invoiceRepository.GetPagedAsync(CurrentTenantId, criteria);
        foreach (var inv in paged.Items)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
            await AddFinePreviewAsync(inv);
        }
        return paged;
    }

    private async Task AddFinePreviewAsync(Invoice invoice)
    {
        if (invoice.Status != "Paid" && invoice.DueDate < DateTime.UtcNow)
        {
            var fine = await _fineService.CalculateFineAsync(invoice, DateTime.UtcNow);
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
        // Get base stats from repository
        var (_, collected) = await _invoiceRepository.GetSummaryStatsAsync(CurrentTenantId, associationId ?? CurrentAssociationId, assetId, assetIds);
        
        // Calculate REAL unpaid balance including ONLY virtual dynamic fines (to avoid double-counting persisted maintenance items)
        IEnumerable<Invoice> unpaidInvoices;
        
        // If userId is provided, resolve their asset IDs first
        if (userId.HasValue && (assetIds == null || !assetIds.Any()))
        {
            var occupancies = await _occupancyRepository.GetByUserIdAsync(userId.Value, CurrentTenantId, associationId ?? CurrentAssociationId);
            assetIds = occupancies.Select(o => o.AssetId).ToList();
        }

        if (assetId.HasValue)
        {
            unpaidInvoices = (await GetInvoicesByAssetIdAsync(assetId.Value, associationId)).Where(i => i.Status != "Paid");
        }
        else if (assetIds != null && assetIds.Any())
        {
            var allInUserScope = new List<Invoice>();
            foreach(var id in assetIds)
            {
                allInUserScope.AddRange(await GetInvoicesByAssetIdAsync(id, associationId));
            }
            unpaidInvoices = allInUserScope.Where(i => i.Status != "Paid");
        }
        else
        {
            unpaidInvoices = (await GetAllInvoicesAsync(associationId)).Where(i => i.Status != "Paid");
        }

        // SMART SUM: Amount (Principal) + all Fine items + any virtual items
        decimal realUnpaid = 0;
        foreach (var inv in unpaidInvoices)
        {
            realUnpaid += await GetTotalInvoiceAmountAsync(inv);
        }
        
        decimal totalWallet = 0;
        var ids = assetId.HasValue ? new[] { assetId.Value } : (assetIds ?? Enumerable.Empty<int>());
        foreach (var aid in ids)
        {
            var txs = await GetAssetTransactionsAsync(aid);
            var advances = txs.Where(t => t.Type == "Credit" && (t.Category == "Payment" || t.Category == "Advance Payment") && !t.InvoiceId.HasValue).Sum(t => t.Amount);
            var settlements = txs.Where(t => t.Type == "Debit" && (t.Category == "Credit Settlement" || t.Category == "Internal Credit Transfer")).Sum(t => t.Amount);
            totalWallet += (advances - settlements);
        }

        return new FinanceSummary 
        { 
            TotalUnpaid = realUnpaid, 
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
        if (invoice.AssetId.HasValue)
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

    public async Task<IEnumerable<Payment>> GetPaymentsAsync(int? associationId = null)
    {
        return await _paymentRepository.GetByTenantIdAsync(CurrentTenantId, associationId ?? CurrentAssociationId);
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
            var txs = await GetAssetTransactionsAsync(asset.AssetId);
            var advances = txs.Where(t => t.Type == "Credit" && (t.Category == "Payment" || t.Category == "Advance Payment") && !t.InvoiceId.HasValue).Sum(t => t.Amount);
            var settlements = txs.Where(t => t.Type == "Debit" && (t.Category == "Credit Settlement" || t.Category == "Internal Credit Transfer")).Sum(t => t.Amount);
            totalWalletPower += (advances - settlements);
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
            var txs = await GetAssetTransactionsAsync(asset.AssetId);
            var assetAdvances = txs.Where(t => t.Type == "Credit" && (t.Category == "Payment" || t.Category == "Advance Payment") && !t.InvoiceId.HasValue).Sum(t => t.Amount);
            var assetSettlements = txs.Where(t => t.Type == "Debit" && (t.Category == "Credit Settlement" || t.Category == "Internal Credit Transfer")).Sum(t => t.Amount);
            var assetWalletPower = (assetAdvances - assetSettlements);

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
        // 1. Unified Unpaid Invoices (including fines)
        var invoices = (await GetAllInvoicesAsync(associationId)).Where(i => i.Status != "Paid");
        decimal totalOutstanding = 0;
        foreach (var inv in invoices)
        {
            totalOutstanding += await GetTotalInvoiceAmountAsync(inv);
        }

        // 2. Unified Advance Credits (Scan all units to match Resident logic)
        // Note: associationId is passed for cross-tenant multi-asset support
        var assets = await _assetRepository.GetHierarchyAsync(tenantId, associationId);
        decimal totalCredits = 0;
        int unitsWithCredit = 0;

        foreach (var asset in assets)
        {
            var summary = await GetFinanceSummaryAsync(associationId, assetId: asset.AssetId);
            if (summary.TotalAdvanceCredits > 0)
            {
                totalCredits += summary.TotalAdvanceCredits;
                unitsWithCredit++;
            }
        }

        return (totalOutstanding, totalCredits, unitsWithCredit);
    }

    public async Task<IEnumerable<AdvancePaymentHistory>> GetAdvancesAsync(int associationId, int tenantId, int? userId = null, int? assetId = null)
    {
        return await _paymentRepository.GetAdvancesAsync(tenantId, associationId, userId, assetId);
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
}
