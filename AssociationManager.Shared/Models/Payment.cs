using System;

namespace AssociationManager.Shared.Models;

public class Payment
{
    public int PaymentId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public int UserId { get; set; }
    public int? AssetId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public string Status { get; set; } = "Pending";
    public string? Notes { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public string? GatewayReference { get; set; }
    public int? InvoiceId { get; set; }
}
