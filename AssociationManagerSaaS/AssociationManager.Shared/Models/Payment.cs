using System;

namespace AssociationManager.Shared.Models
{
    public class Payment : BaseEntity, ITenantEntity
    {
        public int TenantId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "USD";
        public string Status { get; set; } = "Pending";
        public string? ExternalId { get; set; } // e.g. Stripe ID
    }
}
