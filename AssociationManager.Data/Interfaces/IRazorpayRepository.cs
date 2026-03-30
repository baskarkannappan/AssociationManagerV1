using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IRazorpayRepository
{
    Task<TenantPaymentConfig?> GetPaymentConfigAsync(int tenantId);
    Task<int> CreateOrderAsync(PaymentOrder order);
    Task<PaymentOrder?> GetOrderByRazorpayIdAsync(string razorpayOrderId, int tenantId);
    Task<bool> UpdateOrderStatusAsync(string razorpayOrderId, string status, int tenantId);
    Task<int> CreateTransactionAsync(PaymentTransaction transaction);
    Task<int> CreateWebhookLogAsync(PaymentWebhookLog log);
    Task<IEnumerable<PaymentHistoryItem>> GetTransactionsByInvoiceIdAsync(int invoiceId, int tenantId);
    Task<IEnumerable<PaymentOrder>> GetOrdersByInvoiceIdAsync(int invoiceId, int tenantId);
    Task<bool> TransactionExistsAsync(string razorpayPaymentId, int tenantId);
}
