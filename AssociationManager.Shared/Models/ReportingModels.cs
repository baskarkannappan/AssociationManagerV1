using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class AgingBucket
{
    public decimal Amount { get; set; }
    public string BucketName { get; set; } = string.Empty;
}

public class AgingReport
{
    public decimal Current { get; set; }     // Overdue 1-30 days
    public decimal Bucket31_60 { get; set; }
    public decimal Bucket61_90 { get; set; }
    public decimal Over90 { get; set; }
    public decimal TotalOverdue => Current + Bucket31_60 + Bucket61_90 + Over90;
}

public class MonthlyCollectionEfficiency
{
    public string Month { get; set; } = string.Empty;
    public decimal BilledAmount { get; set; }
    public decimal CollectedAmount { get; set; }
    public decimal EfficiencyPercentage => BilledAmount == 0 ? 0 : Math.Round((CollectedAmount / BilledAmount) * 100, 2);
}

public class FinancialMetricsReport
{
    public AgingReport Aging { get; set; } = new();
    public List<MonthlyCollectionEfficiency> MonthlyEfficiency { get; set; } = new();
    public decimal TotalPortfolioOutstanding { get; set; }
    public decimal TotalCollectedAllTime { get; set; }
}
