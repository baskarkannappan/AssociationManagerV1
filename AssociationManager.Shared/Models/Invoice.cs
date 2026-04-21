using System;

namespace AssociationManager.Shared.Models;

public class Invoice
{
    public int InvoiceId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public int? AssetId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Amount { get; set; }
    public DateTime DueDate { get; set; }
    public int? BillingBatchId { get; set; }
    public string Status { get; set; } = "Unpaid";
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public List<InvoiceLineItem> LineItems { get; set; } = new();

    // Navigation helper (not mapped by Dapper automatically)
    public string? AssetName { get; set; }
    public bool IsAdvancePaid { get; set; }
    public string? TempId { get; set; } // For bulk mapping
}
