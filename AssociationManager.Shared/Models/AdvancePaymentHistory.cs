using System;

namespace AssociationManager.Shared.Models;

public class AdvancePaymentHistory
{
    public int PaymentId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "INR";
    public DateTime Date { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? ReferenceId { get; set; }
    public string? Notes { get; set; }
    
    // Joined Info
    public string? UnitName { get; set; }
    public string? ResidentName { get; set; }
    public string? ResidentEmail { get; set; }
}
