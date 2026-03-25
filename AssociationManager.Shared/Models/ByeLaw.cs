using System;

namespace AssociationManager.Shared.Models;

public class ByeLaw
{
    public int ByeLawId { get; set; }
    public int AssociationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime EffectiveDate { get; set; }
    public string? Version { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
    public byte[]? DocumentContent { get; set; }
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
}
