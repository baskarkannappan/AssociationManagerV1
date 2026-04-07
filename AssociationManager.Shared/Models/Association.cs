using System;

namespace AssociationManager.Shared.Models;

public class Association
{
    public int AssociationId { get; set; }
    public int TenantId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int? CreatedBy { get; set; }
    public string? PlanName { get; set; }
    public string? AdminEmail { get; set; }
    public int? PlatformAccountId { get; set; }
    public string? BillingAccountName { get; set; }
    public bool AdminPaysFee { get; set; } = true;
    public decimal PlatformWalletBalance { get; set; } = 0;
    public string Status { get; set; } = "Active";
}
