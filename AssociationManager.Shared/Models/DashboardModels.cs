using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class AssociationDashboardMetrics
{
    public int TotalMembers { get; set; }
    public decimal TotalRevenueCollected { get; set; }
    public decimal TotalOutstanding { get; set; }
    public decimal TotalAdvanceCredits { get; set; }
    public int UnitsWithCredit { get; set; }
    public int PendingWorkOrders { get; set; }
    public List<AuditLog> RecentActivity { get; set; } = new();
}

public class ResidentDashboardMetrics
{
    public decimal BalanceDue { get; set; }
    public decimal WalletBalance { get; set; } // Gross Prepaid Surplus (Payments - Settlements)
    public decimal NetPosition { get; set; }   // True Wallet - Debt
    public int PendingInvoices { get; set; }
    public int ActiveWorkOrders { get; set; }
    public List<AuditLog> MyRecentActivity { get; set; } = new();
}

public class AdvanceMoneyMetrics
{
    public decimal TotalAdvanceCredits { get; set; }
    public int UnitsWithCredit { get; set; }
}
