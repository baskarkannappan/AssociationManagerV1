using System;

namespace AssociationManager.Shared.Models;

public class PaymentTransaction
{
    public int Id { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public int? PaymentOrderId { get; set; }
    public string RazorpayPaymentId { get; set; } = string.Empty;
    public string RazorpayOrderId { get; set; } = string.Empty;
    public string RazorpaySignature { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string? RawResponse { get; set; }
    public string? PrimaryAccountName { get; set; }
    public string? PrimaryAccountNumber { get; set; }
    public string? PaymentMethod { get; set; }
    public string? BankName { get; set; }
    public string? BankRrn { get; set; }
    public string? CardNetwork { get; set; }
    public decimal? GatewayFee { get; set; }
    public decimal? GatewayTax { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
