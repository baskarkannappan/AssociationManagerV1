using System;

namespace AssociationManager.Shared.Models
{
    public class User : BaseEntity
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? GoogleId { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
