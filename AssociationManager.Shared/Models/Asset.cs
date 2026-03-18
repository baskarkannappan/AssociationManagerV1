using AssociationManager.Shared.Enums;
using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class Asset
{
    public int AssetId { get; set; }
    public int? ParentId { get; set; }
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public AssetType AssetType { get; set; }
    
    // Extensibility for custom fields like "Area", "LockerId", "ParkingSlot"
    public string? MetadataJson { get; set; }
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int CreatedBy { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation-like property for hierarchy
    public List<Asset> Children { get; set; } = new();
}
