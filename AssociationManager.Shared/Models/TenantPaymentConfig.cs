using System;

namespace AssociationManager.Shared.Models;

public class TenantPaymentConfig
{
    public int Id { get; set; }
    public int TenantId { get; set; }
    public string RazorpayKeyId { get; set; } = string.Empty;
    public string? RazorpayKeySecret { get; set; }
    public string? RazorpayWebhookSecret { get; set; }
    public string? WebhookSecret { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
}
