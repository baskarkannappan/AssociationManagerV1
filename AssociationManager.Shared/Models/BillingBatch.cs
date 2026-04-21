using System;

namespace AssociationManager.Shared.Models;

public class BillingBatch
{
    public int BillingBatchId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public int Month { get; set; }
    public int Year { get; set; }
    public string Status { get; set; } = "Committed"; // Draft, Committed, Reversed
    public decimal TotalAmount { get; set; }
    public int InvoicesGenerated { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public bool HasDraftInvoices { get; set; }
}
