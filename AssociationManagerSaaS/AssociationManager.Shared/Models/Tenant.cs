using System;

namespace AssociationManager.Shared.Models
{
    public class Tenant : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string Identifier { get; set; } = string.Empty; // e.g., "org1"
        public bool IsActive { get; set; } = true;
    }
}
