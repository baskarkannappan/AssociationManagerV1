using System;

namespace AssociationManager.Shared.Models;

public class PaymentWebhookLog
{
    public int Id { get; set; }
    public int? TenantId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string RawPayload { get; set; } = string.Empty;
    public string? Signature { get; set; }
    public bool IsProcessed { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
