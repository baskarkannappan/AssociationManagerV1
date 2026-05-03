using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Azure.Storage.Queues;
using MailKit.Net.Smtp;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;
using System;
using System.Text.Json;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<bool> SendEmailAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        try
        {
            // 1. Check if Email Feature is Enabled
            var isEnabled = _configuration.GetValue<bool>("EmailSettings:Enabled");
            if (!isEnabled)
            {
                _logger.LogInformation("Email feature is disabled in configuration. Skipping email to {Email}", toEmail);
                return true; // Return true as if it was handled
            }

            // 2. Check Delivery Method
            var deliveryMethod = _configuration["EmailSettings:DeliveryMethod"] ?? "Smtp";

            if (string.Equals(deliveryMethod, "AzureQueue", StringComparison.OrdinalIgnoreCase))
            {
                return await SendViaAzureQueueAsync(toEmail, toName, subject, htmlBody);
            }
            
            // 3. Default to Legacy SMTP (Existing Functionality)
            return await SendViaSmtpAsync(toEmail, toName, subject, htmlBody);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to process email to {Email}", toEmail);
            return false;
        }
    }

    private async Task<bool> SendViaAzureQueueAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        try
        {
            var connectionString = _configuration["EmailSettings:AzureStorageConnectionString"];
            var queueName = _configuration["EmailSettings:QueueName"] ?? "email-requests";

            if (string.IsNullOrEmpty(connectionString))
            {
                _logger.LogError("Azure Storage Connection String is missing in configuration.");
                return false;
            }

            var queueClient = new QueueClient(connectionString, queueName);
            await queueClient.CreateIfNotExistsAsync();

            var message = new EmailMessage
            {
                ToEmail = toEmail,
                ToName = toName,
                Subject = subject,
                HtmlBody = htmlBody,
                FromEmail = _configuration["Smtp:FromEmail"],
                FromName = _configuration["Smtp:FromName"]
            };

            var messageJson = JsonSerializer.Serialize(message);
            // Azure Queue messages are typically Base64 encoded in some SDK versions/triggers
            var messageBytes = System.Text.Encoding.UTF8.GetBytes(messageJson);
            await queueClient.SendMessageAsync(Convert.ToBase64String(messageBytes));

            _logger.LogInformation("Email request queued to Azure Storage: {Email}", toEmail);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to queue email to Azure Storage for {Email}", toEmail);
            return false;
        }
    }

    private async Task<bool> SendViaSmtpAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        var host = _configuration["Smtp:Host"] ?? "smtp.gmail.com";
        var port = int.Parse(_configuration["Smtp:Port"] ?? "587");
        var username = _configuration["Smtp:Username"];
        var password = _configuration["Smtp:Password"];
        var fromEmail = _configuration["Smtp:FromEmail"] ?? username;
        var fromName = _configuration["Smtp:FromName"] ?? "Association Manager";

        if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password) || string.IsNullOrEmpty(toEmail))
        {
            _logger.LogError("SMTP credentials not configured or recipient address missing.");
            return false;
        }

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, fromEmail ?? username));
        message.To.Add(new MailboxAddress(toName ?? toEmail, toEmail));
        message.Subject = subject;

        var bodyBuilder = new BodyBuilder { HtmlBody = htmlBody };
        message.Body = bodyBuilder.ToMessageBody();

        using var client = new SmtpClient();
        await client.ConnectAsync(host, port, MailKit.Security.SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(username, password);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);

        return true;
    }
}
