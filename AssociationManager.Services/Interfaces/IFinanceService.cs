using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IFinanceService
{
    // Invoice Operations
    Task<Invoice?> GetInvoiceByIdAsync(int id);
    Task<IEnumerable<Invoice>> GetAllInvoicesAsync();
    Task<IEnumerable<Invoice>> GetInvoicesByAssetIdAsync(int assetId);
    Task<int> CreateInvoiceAsync(Invoice invoice);
    Task<bool> UpdateInvoiceStatusAsync(int id, string status);
    Task<bool> DeleteInvoiceAsync(int id);

    // Payment Operations
    Task<IEnumerable<Payment>> GetPaymentsAsync();
    Task<int> CreatePaymentAsync(Payment payment);
}
