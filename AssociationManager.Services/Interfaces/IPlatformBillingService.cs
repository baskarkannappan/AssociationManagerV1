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
}
