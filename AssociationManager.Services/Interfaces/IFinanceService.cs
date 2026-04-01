using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IFinanceService
{
    // Invoice Operations
    Task<Invoice?> GetInvoiceByIdAsync(int id, int? associationId = null);
    Task<IEnumerable<Invoice>> GetAllInvoicesAsync(int? associationId = null);
    Task<IEnumerable<Invoice>> GetInvoicesByAssetIdAsync(int assetId, int? associationId = null);
    Task<PagedResult<Invoice>> GetPagedInvoicesAsync(InvoiceSearchCriteria criteria);
    Task<(decimal TotalUnpaid, decimal Collected30Days)> GetFinanceSummaryAsync(int? associationId = null, int? assetId = null);
    Task<int> CreateInvoiceAsync(Invoice invoice, IEnumerable<InvoiceLineItem>? lineItems = null);
    Task<bool> UpdateInvoiceStatusAsync(int id, string status, int? associationId = null);
    Task<bool> DeleteInvoiceAsync(int id, int? associationId = null);

    // Payment Operations
    Task<IEnumerable<Payment>> GetPaymentsAsync(int? associationId = null);
    Task<int> CreatePaymentAsync(Payment payment);

    // Ledger & Transactions
    Task<IEnumerable<Transaction>> GetAssetTransactionsAsync(int assetId);
    Task<decimal> GetAssetBalanceAsync(int assetId);
    Task<IEnumerable<Transaction>> GetTenantTransactionsAsync(DateTime? start = null, DateTime? end = null);

    // Bank Account Configuration
    Task<AssociationBankDetails?> GetBankDetailsAsync(int associationId);
    Task<bool> UpdateBankDetailsAsync(AssociationBankDetails details);

    // Auto-Settlement
    Task<bool> AutoSettleInvoicesAsync(int assetId, int? associationId = null);
    
    Task<(decimal TotalOutstanding, decimal TotalCredits, int UnitsWithCredit)> GetAssociationFinanceSummaryAsync(int associationId, int tenantId);
    Task<IEnumerable<AdvancePaymentHistory>> GetAdvancesAsync(int associationId, int tenantId, int? userId = null, int? assetId = null);
}
