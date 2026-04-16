using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IEmailTemplateService
{
    Task<string> GenerateInvoiceHtmlAsync(int invoiceId);
}
