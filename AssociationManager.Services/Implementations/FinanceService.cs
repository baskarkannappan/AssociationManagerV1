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

    public FinanceService(
        IInvoiceRepository invoiceRepository, 
        IPaymentRepository paymentRepository, 
        ILedgerService ledgerService,
        ITenantContext tenantContext,
        IAssociationRepository associationRepository,
        IOccupancyRepository occupancyRepository)
    {
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _ledgerService = ledgerService;
        _tenantContext = tenantContext;
        _associationRepository = associationRepository;
        _occupancyRepository = occupancyRepository;
    }

    private int CurrentTenantId => _tenantContext.TenantId;
    private int CurrentAssociationId => _tenantContext.AssociationId;

    public async Task<Invoice?> GetInvoiceByIdAsync(int id, int? associationId = null)
    {
        var invoice = await _invoiceRepository.GetByIdAsync(id, CurrentTenantId, associationId ?? CurrentAssociationId);
        if (invoice != null)
        {
            invoice.LineItems = (await _invoiceRepository.GetLineItemsAsync(id)).ToList();
        }
        return invoice;
    }

    public async Task<IEnumerable<Invoice>> GetAllInvoicesAsync(int? associationId = null)
    {
        var invoices = await _invoiceRepository.GetAllAsync(CurrentTenantId, associationId ?? CurrentAssociationId);
        foreach (var inv in invoices)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
        }
        return invoices;
    }

    public async Task<IEnumerable<Invoice>> GetInvoicesByAssetIdAsync(int assetId, int? associationId = null)
    {
        var invoices = await _invoiceRepository.GetByAssetIdAsync(assetId, CurrentTenantId, associationId ?? CurrentAssociationId);
        foreach (var inv in invoices)
        {
            inv.LineItems = (await _invoiceRepository.GetLineItemsAsync(inv.InvoiceId)).ToList();
        }
        return invoices;
    }

    public async Task<PagedResult<Invoice>> GetPagedInvoicesAsync(InvoiceSearchCriteria criteria)
    {
        if (criteria.AssociationId == null) criteria.AssociationId = CurrentAssociationId;
        return await _invoiceRepository.GetPagedAsync(CurrentTenantId, criteria);
    }

    public async Task<FinanceSummary> GetFinanceSummaryAsync(int? associationId = null, int? assetId = null, IEnumerable<int>? assetIds = null)
    {
        var (unpaid, collected) = await _invoiceRepository.GetSummaryStatsAsync(CurrentTenantId, associationId ?? CurrentAssociationId, assetId, assetIds);
        
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
            TotalUnpaid = unpaid, 
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
        // USER REQ: Resident for each asset should display the asset specific pending amount. 
        // It should not use wallet amount. Negative (-2000) should be 0.
        var invoices = await _invoiceRepository.GetByAssetIdAsync(assetId, CurrentTenantId, CurrentAssociationId);
        return invoices.Where(i => i.Status != "Paid").Sum(i => i.Amount);
    }

    public async Task<bool> AutoSettleInvoicesAsync(int assetId, int? associationId = null)
    {
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

        decimal remainingSettleAmount = invoice.Amount;
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
            await _invoiceRepository.UpdateStatusAsync(invoiceId, "Paid", CurrentTenantId, invoice.AssociationId, isAdvancePaid: true);
            return true;
        }

        return remainingSettleAmount < invoice.Amount;
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
        return await _paymentRepository.GetAssociationSummaryAsync(tenantId, associationId);
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
}
