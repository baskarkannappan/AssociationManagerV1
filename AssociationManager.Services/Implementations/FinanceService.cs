using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class FinanceService : IFinanceService
{
    private readonly IInvoiceRepository _invoiceRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ILedgerService _ledgerService;
    private readonly ITenantContext _tenantContext;
    private readonly IAssociationRepository _associationRepository;

    public FinanceService(
        IInvoiceRepository invoiceRepository, 
        IPaymentRepository paymentRepository, 
        ILedgerService ledgerService,
        ITenantContext tenantContext,
        IAssociationRepository associationRepository)
    {
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _ledgerService = ledgerService;
        _tenantContext = tenantContext;
        _associationRepository = associationRepository;
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
        return new FinanceSummary { TotalUnpaid = unpaid, Collected30Days = collected };
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

            // AUTO-SETTLE: Check if user has advance credit to pay this new invoice
            await AutoSettleInvoicesAsync(invoice.AssetId.Value);
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

            // If this is an advance payment (no InvoiceId), attempt to settle any existing unpaid invoices
            if (!payment.InvoiceId.HasValue)
            {
                await AutoSettleInvoicesAsync(payment.AssetId.Value);
            }
        }

        // If Payment is linked to an Invoice, update invoice status
        if (payment.InvoiceId.HasValue)
        {
            await _invoiceRepository.UpdateStatusAsync(payment.InvoiceId.Value, "Paid", CurrentTenantId, CurrentAssociationId);
        }

        // ALWAYS attempt to settle any other unpaid invoices for this asset if a surplus exists
        if (payment.AssetId.HasValue)
        {
            await AutoSettleInvoicesAsync(payment.AssetId.Value);
        }

        return id;
    }

    public async Task<IEnumerable<Transaction>> GetAssetTransactionsAsync(int assetId)
    {
        return await _ledgerService.GetAssetTransactionsAsync(assetId);
    }

    public async Task<decimal> GetAssetBalanceAsync(int assetId)
    {
        return await _ledgerService.GetAssetBalanceAsync(assetId);
    }

    public async Task<bool> AutoSettleInvoicesAsync(int assetId, int? associationId = null)
    {
        return await _paymentRepository.AutoSettleAsync(assetId, CurrentTenantId, associationId ?? CurrentAssociationId, _tenantContext.UserId);
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
