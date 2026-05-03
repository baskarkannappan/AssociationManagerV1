namespace AssociationManager.Shared.Models;

public class FinanceSummary
{
    public decimal TotalUnpaid { get; set; }
    public decimal Collected30Days { get; set; }
    public decimal TotalAdvanceCredits { get; set; }
}

public class UserFinanceSummary
{
    public int UserId { get; set; }
    public decimal TotalUnpaid { get; set; }
    public decimal TotalAdvanceCredits { get; set; }
}
