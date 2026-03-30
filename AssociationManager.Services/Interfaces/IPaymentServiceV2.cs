using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IPaymentServiceV2
{
    Task<RazorpayOrderResponse> CreateOrderAsync(RazorpayOrderRequest request);
    Task<bool> VerifySignatureAsync(RazorpayVerifyRequest request);
    Task ProcessWebhookAsync(string payload, string signature);
    Task<object> GetPaymentHistoryAsync(int invoiceId);
}
