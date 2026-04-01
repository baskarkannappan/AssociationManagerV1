using System;

namespace AssociationManager.Shared.Models;

public class PaymentOrder
{
    public int Id { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public int UserId { get; set; }
    public string RazorpayOrderId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "INR";
    public string Status { get; set; } = "Created"; // Created, Attempted, Paid, Failed
    public int? InvoiceId { get; set; }
    public int? AssetId { get; set; }
    public string? Receipt { get; set; }
    public string? PrimaryAccountName { get; set; }
    public string? PrimaryAccountNumber { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
