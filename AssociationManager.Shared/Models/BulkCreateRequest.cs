using AssociationManager.Shared.Enums;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public enum AssetTemplateType
{
    ResidentialBuilding = 1,
    VillaCommunity = 2,
    BulkUnits = 3,
    Floors = 4,
    CommonAreas = 5,
    Amenities = 6,
    SecurityGates = 7
}

public class BulkCreateRequest
{
    public AssetTemplateType TemplateType { get; set; }
    public string BaseName { get; set; } = string.Empty;
    public int? ParentId { get; set; }
    
    // For ResidentialBuilding
    public int? NumberOfFloors { get; set; }
    public int? UnitsPerFloor { get; set; }
    
    // For VillaCommunity / BulkUnits
    public int? Quantity { get; set; }
    
    // Detailed Metadata
    public string? RoomConfig { get; set; } // e.g. "1 BHK", "Studio"
    public decimal? TotalAreaSqFt { get; set; }
    public string? BaseAddress { get; set; }
    
    // Common metadata for dummy values
    public string? Description { get; set; }
}
