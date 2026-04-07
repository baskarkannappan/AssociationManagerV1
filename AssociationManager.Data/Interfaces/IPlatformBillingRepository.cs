using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IPlatformBillingRepository
{
    Task<int> CreateInvoiceAsync(PlatformInvoice invoice);
    Task<IEnumerable<PlatformInvoice>> GetInvoicesByAssociationIdAsync(int associationId);
    Task<IEnumerable<PlatformInvoice>> GetAllInvoicesAsync();
    Task<int> RecordPaymentAsync(PlatformPayment payment);
    Task<bool> UpdateInvoiceStatusAsync(int invoiceId, string status);
    Task<decimal> GetRevenueAsync(DateTime startDate, DateTime endDate);
    
    // Wallet & Advance Payments
    Task<decimal> GetWalletBalanceAsync(int associationId);
    Task<bool> UpdateWalletBalanceAsync(int associationId, decimal delta);
    Task<int> RecordAdvancePaymentAsync(PlatformAdvanceHistory advance);
    Task<PagedResult<PlatformAdvanceHistory>> GetPagedAdvanceHistoryAsync(int associationId, AdvanceSearchCriteria criteria);
}
