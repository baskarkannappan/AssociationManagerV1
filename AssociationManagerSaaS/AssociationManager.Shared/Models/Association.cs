namespace AssociationManager.Shared.Models
{
    public class Association : BaseEntity, ITenantEntity
    {
        public int TenantId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}
