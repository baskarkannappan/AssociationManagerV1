using System;
using AssociationManager.Shared.Enums;

namespace AssociationManager.Shared.Models;

public class CommunicationLog
{
    public int LogId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public string RecipientEmail { get; set; } = string.Empty;
    public string? RecipientName { get; set; }
    public string Subject { get; set; } = string.Empty;
    public string HtmlBody { get; set; } = string.Empty;
    
    public string? ReferenceType { get; set; } // e.g., "Invoice"
    public int? ReferenceId { get; set; } // e.g., InvoiceId
    
    public CommunicationStatus Status { get; set; } = CommunicationStatus.Posted;
    public string? ErrorMessage { get; set; }
    public int RetryCount { get; set; } = 0;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedDate { get; set; }
    public DateTime? ScheduledDate { get; set; }
}
