using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IEmailService
{
    Task<bool> SendEmailAsync(string toEmail, string toName, string subject, string htmlBody);
}
