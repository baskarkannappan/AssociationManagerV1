using System;

namespace AssociationManager.Shared.Models;

public class AuditLog
{
    public int AuditLogId { get; set; }
    public int TenantId { get; set; }
    public int? AssociationId { get; set; }
    public int? UserId { get; set; }
    public int? AssetId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? Entity { get; set; }
    public int? EntityId { get; set; }
    public string? IpAddress { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
