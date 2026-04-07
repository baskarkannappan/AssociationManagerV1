using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IPlatformBillingService
{
    Task<int> GenerateMonthlyBillsAsync(int? month = null, int? year = null);
    Task<IEnumerable<PlatformInvoice>> GetInvoicesForAssociationAsync(int associationId);
    Task<IEnumerable<PlatformInvoice>> GetAllInvoicesAsync();
    Task<bool> ProcessPaymentAsync(PlatformPayment payment);
    Task<RazorpayOrderResponse> CreateOrderAsync(int invoiceId);
    Task<bool> VerifyPaymentAsync(RazorpayVerifyRequest request);
    Task<PlatformAccount?> GetBillingAccountByAssociationIdAsync(int associationId);
    
    // Wallet & Advance Payments
    Task<decimal> GetPlatformWalletBalanceAsync(int associationId);
    Task<PagedResult<PlatformAdvanceHistory>> GetPlatformAdvanceHistoryAsync(int associationId, AdvanceSearchCriteria criteria);
    Task<RazorpayOrderResponse> CreateTopupOrderAsync(decimal amount);
    Task<bool> VerifyTopupPaymentAsync(RazorpayVerifyRequest request);
    Task<bool> SettleInvoiceWithWalletAsync(int invoiceId);
}
