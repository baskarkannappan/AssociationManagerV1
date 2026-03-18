using System;

namespace AssociationManager.Shared.Models;

public class Broadcast
{
    public int BroadcastId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string Category { get; set; } = "General";
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int CreatedBy { get; set; }
    public bool IsPinned { get; set; }
    public DateTime? ExpiresDate { get; set; }
    public int? AssetId { get; set; }

    // Navigation helpers
    public string? AuthorName { get; set; }
    public string? AssetName { get; set; }
}
