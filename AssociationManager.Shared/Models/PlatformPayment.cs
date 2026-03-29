using System;

namespace AssociationManager.Shared.Models;

public class PlatformPayment
{
    public int PlatformPaymentId { get; set; }
    public int PlatformInvoiceId { get; set; }
    public decimal Amount { get; set; }
    public DateTime PaymentDate { get; set; }
    public string? TransactionRef { get; set; }
}
