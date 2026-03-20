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

    public FinanceService(
        IInvoiceRepository invoiceRepository, 
        IPaymentRepository paymentRepository, 
        ILedgerService ledgerService,
        ITenantContext tenantContext)
    {
        _invoiceRepository = invoiceRepository;
        _paymentRepository = paymentRepository;
        _ledgerService = ledgerService;
        _tenantContext = tenantContext;
    }

    private int CurrentTenantId => _tenantContext.TenantId;
    private int CurrentAssociationId => _tenantContext.AssociationId;

    public async Task<Invoice?> GetInvoiceByIdAsync(int id, int? associationId = null)
    {
        return await _invoiceRepository.GetByIdAsync(id, CurrentTenantId, associationId ?? CurrentAssociationId);
    }

    public async Task<IEnumerable<Invoice>> GetAllInvoicesAsync(int? associationId = null)
    {
        return await _invoiceRepository.GetAllAsync(CurrentTenantId, associationId ?? CurrentAssociationId);
    }

    public async Task<IEnumerable<Invoice>> GetInvoicesByAssetIdAsync(int assetId, int? associationId = null)
    {
        return await _invoiceRepository.GetByAssetIdAsync(assetId, CurrentTenantId, associationId ?? CurrentAssociationId);
    }

    public async Task<int> CreateInvoiceAsync(Invoice invoice)
    {
        invoice.TenantId = CurrentTenantId;
        invoice.AssociationId = CurrentAssociationId;
        var id = await _invoiceRepository.CreateAsync(invoice);

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
                Description = payment.Notes ?? "Payment Received"
            });
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
        return await _ledgerService.GetAssetBalanceAsync(assetId);
    }

    public async Task<IEnumerable<Transaction>> GetTenantTransactionsAsync(DateTime? start = null, DateTime? end = null)
    {
        return await _ledgerService.GetTenantTransactionsAsync(start, end);
    }
}
