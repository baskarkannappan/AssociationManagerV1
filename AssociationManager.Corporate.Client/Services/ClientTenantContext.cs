using AssociationManager.Shared.Interfaces;

namespace AssociationManager.Corporate.Client.Services;

public class ClientTenantContext : ITenantContext
{
    public int AssociationId { get; set; }
    public int TenantId { get; set; }
    public int UserId { get; set; }
    public bool IsPlatformAdmin { get; set; }
    public bool IsSystemAdmin { get; set; }
}
