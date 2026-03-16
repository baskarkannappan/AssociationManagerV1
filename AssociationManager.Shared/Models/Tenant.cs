using System;

namespace AssociationManager.Shared.Models;

public class Tenant
{
    public int TenantId { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
}
