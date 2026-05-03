using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class InvoiceBatchRequest
{
    public int AssociationId { get; set; }
    public int Month { get; set; }
    public int Year { get; set; }
    public DateTime DueDate { get; set; } = DateTime.UtcNow.AddDays(15);
    public bool DryRun { get; set; } = true;
}

public class InvoiceBatchResult
{
    public int TotalAssets { get; set; }
    public int InvoicesGenerated { get; set; }
    public int SkippedAssets { get; set; }
    public decimal TotalAmount { get; set; }
    public List<InvoicePreviewItem> Previews { get; set; } = new();
    public string Message { get; set; } = string.Empty;
    public bool IsLocked { get; set; }
}

public class InvoicePreviewItem
{
    public int AssetId { get; set; }
    public string AssetName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
}
