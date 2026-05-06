using System;

namespace AssociationManager.Shared.Models;

public class User
{
    public int UserId { get; set; }
    public int TenantId { get; set; }
    public string GoogleId { get; set; } = string.Empty;
    public string? SubjectId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? PictureUrl { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime? LastLoginDate { get; set; }
    public bool IsActive { get; set; } = true;
    public string Role { get; set; } = "User";
    public int? AssociationId { get; set; }
    public decimal Balance { get; set; }
}
