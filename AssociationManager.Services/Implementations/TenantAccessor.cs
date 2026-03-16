using AssociationManager.Services.Interfaces;

namespace AssociationManager.Services.Implementations;

public class TenantAccessor : ITenantAccessor
{
    public int? TenantId { get; set; }
}
