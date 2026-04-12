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
    
    // Helper to access common metadata safely
    public T? GetMetadata<T>(string key)
    {
        if (string.IsNullOrEmpty(MetadataJson)) return default;
        try
        {
            var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(MetadataJson);
            if (dict != null && dict.TryGetValue(key, out var val))
            {
                return (T)Convert.ChangeType(val.ToString() ?? "", typeof(T));
            }
        }
        catch { }
        return default;
    }

    public void SetMetadata(string key, object value)
    {
        var dict = string.IsNullOrEmpty(MetadataJson) 
            ? new Dictionary<string, object>() 
            : System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(MetadataJson) ?? new Dictionary<string, object>();
        
        dict[key] = value;
        MetadataJson = System.Text.Json.JsonSerializer.Serialize(dict);
    }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int CreatedBy { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation-like property for hierarchy
    public List<Asset> Children { get; set; } = new();
}
