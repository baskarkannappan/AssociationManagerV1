using AssociationManager.Shared.Interfaces;

namespace AssociationManager.Client.Services;

public class ClientTenantContext : ITenantContext
{
    public int AssociationId { get; set; }
    public int TenantId { get; set; }
    public int UserId { get; set; }
    public string? Email { get; set; }
    public bool IsPlatformAdmin { get; set; }
    public bool IsSystemAdmin { get; set; }
    public string AssociationStatus { get; set; } = "Active";
    public void SetContext(int tenantId, int associationId, int userId = 0)
    {
        TenantId = tenantId;
        AssociationId = associationId;
        if (userId > 0) UserId = userId;
    }
}
