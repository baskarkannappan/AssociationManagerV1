using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IInvoicePdfService
{
    Task<byte[]> GenerateInvoicePdfAsync(int invoiceId);
}
