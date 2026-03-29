using System;

namespace AssociationManager.Shared.Models;

public class PlatformInvoice
{
    public int PlatformInvoiceId { get; set; }
    public int AssociationId { get; set; }
    public string? AssociationName { get; set; }
    public int PlanId { get; set; }
    public string? PlanName { get; set; }
    public decimal Amount { get; set; }
    public DateTime BillingDate { get; set; }
    public DateTime DueDate { get; set; }
    public string Status { get; set; } = "Unpaid";
}
