namespace AssociationManager.Shared.Interfaces;

public interface ITenantContext
{
    int TenantId { get; }
    int UserId { get; }
}
