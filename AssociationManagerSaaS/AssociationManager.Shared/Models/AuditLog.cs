using System;

namespace AssociationManager.Shared.Models
{
    public class AuditLog : BaseEntity, ITenantEntity
    {
        public int TenantId { get; set; }
        public int UserId { get; set; }
        public string Action { get; set; } = string.Empty;
        public string EntityName { get; set; } = string.Empty;
        public string EntityId { get; set; } = string.Empty;
        public string? Changes { get; set; } // JSON or text
    }
}
