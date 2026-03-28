namespace AssociationManager.Shared.Interfaces;

public interface ITenantContext
{
    int TenantId { get; }
    int AssociationId { get; }
    int UserId { get; }
    string? Email { get; }
    bool IsPlatformAdmin { get; }
    bool IsSystemAdmin { get; }
}
