using System;

namespace AssociationManager.Shared.Models;

public class PaymentHistoryItem
{
    public DateTime CreatedDate { get; set; }
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string ReferenceId { get; set; } = string.Empty;
    public string Method { get; set; } = string.Empty;
    public string? RazorpayOrderId { get; set; }
    public string? PrimaryAccountName { get; set; }
    public string? PrimaryAccountNumber { get; set; }
    public string? PaymentMethod { get; set; }
    public string? BankName { get; set; }
    public string? BankRrn { get; set; }
    public string? CardNetwork { get; set; }
    public decimal? GatewayFee { get; set; }
    public decimal? GatewayTax { get; set; }
}
