using System;

namespace AssociationManager.Shared.Models;

public class PlatformAdvanceHistory
{
    public int PlatformAdvanceId { get; set; }
    public int AssociationId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "INR";
    public DateTime Date { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "Pending";
    public string? TransactionRef { get; set; }
    public string? Description { get; set; }
    public string? Notes { get; set; }
    public int TotalCount { get; set; } // For paging metadata
}
