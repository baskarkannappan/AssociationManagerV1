using System;

namespace AssociationManager.Shared.Models
{
    public abstract class BaseEntity
    {
        public int Id { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }

    public interface ITenantEntity
    {
        int TenantId { get; set; }
    }
}
