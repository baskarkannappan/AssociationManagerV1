using System;

namespace AssociationManager.Shared.Models;

public class RazorpayOrderRequest
{
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "INR";
    public int? InvoiceId { get; set; }
    public int? AssetId { get; set; } // Required for Ledger tracking
    public string? Receipt { get; set; }
    public string? Description { get; set; }
}

public class RazorpayOrderResponse
{
    public string OrderId { get; set; } = string.Empty;
    public string KeyId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "INR";
    public string? Status { get; set; }
}

public class RazorpayVerifyRequest
{
    public string RazorpayPaymentId { get; set; } = string.Empty;
    public string RazorpayOrderId { get; set; } = string.Empty;
    public string RazorpaySignature { get; set; } = string.Empty;
    public int? InvoiceId { get; set; }
}
