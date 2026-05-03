using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Enums;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace AssociationManager.Services.Jobs;

public class EmailDispatchJob
{
    private readonly ICommunicationRepository _communicationRepository;
    private readonly IEmailService _emailService;
    private readonly ILogger<EmailDispatchJob> _logger;

    public EmailDispatchJob(
        ICommunicationRepository communicationRepository,
        IEmailService emailService,
        ILogger<EmailDispatchJob> logger)
    {
        _communicationRepository = communicationRepository;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task ProcessPendingEmailsAsync()
    {
        _logger.LogInformation("Starting Email Dispatch Job at {Time}", DateTime.UtcNow);

        var pendingEmails = await _communicationRepository.GetPendingEmailsAsync();
        int successCount = 0;
        int failureCount = 0;

        foreach (var email in pendingEmails)
        {
            try
            {
                // 1. Mark as InProgress
                await _communicationRepository.UpdateStatusAsync(email.LogId, email.TenantId, (int)CommunicationStatus.InProgress);

                // 2. Send Email
                bool sent = await _emailService.SendEmailAsync(
                    email.RecipientEmail,
                    email.RecipientName ?? "Resident",
                    email.Subject,
                    email.HtmlBody);

                if (sent)
                {
                    // 3. Mark as Success
                    await _communicationRepository.UpdateStatusAsync(email.LogId, email.TenantId, (int)CommunicationStatus.Success);
                    // 4. Finally Mark as Complete (Optional intermediate state if you want history)
                    await _communicationRepository.UpdateStatusAsync(email.LogId, email.TenantId, (int)CommunicationStatus.Complete);
                    successCount++;
                }
                else
                {
                    await _communicationRepository.UpdateStatusAsync(email.LogId, email.TenantId, (int)CommunicationStatus.Failure, "SMTP sending failed.");
                    failureCount++;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing email log #{Id}", email.LogId);
                await _communicationRepository.UpdateStatusAsync(email.LogId, email.TenantId, (int)CommunicationStatus.Failure, ex.Message);
                failureCount++;
            }
        }

        _logger.LogInformation("Email Dispatch Job finished. Success: {Success}, Failure: {Failure}", successCount, failureCount);
    }
}
