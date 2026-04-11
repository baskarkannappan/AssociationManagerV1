using AssociationManager.Shared.Interfaces;

namespace AssociationManager.Services.Implementations;

public class BackgroundTenantContext : ITenantContext
{
    public int TenantId { get; set; }
    public int AssociationId { get; set; }
    public int UserId { get; set; }
    public string? Email { get; set; }
    public bool IsPlatformAdmin { get; set; }
    public bool IsSystemAdmin { get; set; }
    public string AssociationStatus { get; set; } = "Active";

    public void SetContext(int tenantId, int associationId, int userId = 0)
    {
        TenantId = tenantId;
        AssociationId = associationId;
        UserId = userId;
    }
}
