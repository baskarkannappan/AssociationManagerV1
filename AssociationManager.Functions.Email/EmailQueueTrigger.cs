using System.Text.Json;
using AssociationManager.Shared.Models;
using MailKit.Net.Smtp;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;

namespace AssociationManager.Functions.Email;

public class EmailQueueTrigger
{
    private readonly ILogger<EmailQueueTrigger> _logger;
    private readonly IConfiguration _configuration;

    public EmailQueueTrigger(ILogger<EmailQueueTrigger> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    [Function("EmailQueueTrigger")]
    public async Task Run([QueueTrigger("email-requests", Connection = "AzureWebJobsStorage")] string queueMessage)
    {
        _logger.LogInformation("Processing email request from queue.");

        try
        {
            var emailMessage = JsonSerializer.Deserialize<EmailMessage>(queueMessage);
            if (emailMessage == null)
            {
                _logger.LogError("Failed to deserialize email message.");
                return;
            }

            await SendEmailAsync(emailMessage);
            _logger.LogInformation("Email sent successfully to {Email}", emailMessage.ToEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing email from queue.");
            throw; // Re-throw to allow Azure Function retry logic to kick in
        }
    }

    private async Task SendEmailAsync(EmailMessage msg)
    {
        var host = _configuration["Smtp:Host"];
        var portStr = _configuration["Smtp:Port"];
        var port = int.Parse(portStr ?? "587");
        var username = _configuration["Smtp:Username"];
        var password = _configuration["Smtp:Password"];
        var fromEmail = msg.FromEmail ?? _configuration["Smtp:FromEmail"] ?? username;
        var fromName = msg.FromName ?? _configuration["Smtp:FromName"] ?? "Association Manager";

        if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password) || string.IsNullOrEmpty(msg.ToEmail) || string.IsNullOrEmpty(fromEmail))
        {
            throw new Exception("SMTP configuration (Host, Username, Password, FromEmail) or recipient address is missing.");
        }

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, fromEmail));
        message.To.Add(new MailboxAddress(msg.ToName ?? msg.ToEmail, msg.ToEmail));
        message.Subject = msg.Subject;

        var bodyBuilder = new BodyBuilder { HtmlBody = msg.HtmlBody };
        message.Body = bodyBuilder.ToMessageBody();

        using var client = new SmtpClient();
        await client.ConnectAsync(host, port, MailKit.Security.SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(username, password);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}
