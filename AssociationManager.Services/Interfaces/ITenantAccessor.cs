namespace AssociationManager.Services.Interfaces;

public interface ITenantAccessor
{
    int? TenantId { get; set; }
}
