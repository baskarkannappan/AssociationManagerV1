using System;

namespace AssociationManager.Shared.Models;

public class WorkOrder
{
    public int WorkOrderId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public int? AssetId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Priority { get; set; } = "Medium";
    public string Status { get; set; } = "Open";
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int CreatedBy { get; set; }
    public string? AssignedTo { get; set; }
    public DateTime? CompletedDate { get; set; }

    // Navigation helper
    public string? AssetName { get; set; }
}
