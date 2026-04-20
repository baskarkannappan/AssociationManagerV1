using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class AssociationDashboardMetrics
{
    public int TotalMembers { get; set; }
    public int CommitteeCount { get; set; }
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
    public decimal CreditAvailable { get; set; } // Gross Prepaid Surplus (Payments - Settlements)
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

public class ResidentDashboardOverview
{
    public List<Occupancy> Occupancies { get; set; } = new();
    public decimal MyBalance { get; set; }
    public List<Invoice> RecentInvoices { get; set; } = new();
    public ResidentDashboardMetrics Metrics { get; set; } = new();
    public Asset? MyUnit { get; set; }
    public AssociationProfile? Profile { get; set; }
}

public class AdminDashboardOverview
{
    public AssociationDashboardMetrics Metrics { get; set; } = new();
    public int TotalMembers { get; set; }
    public int CommitteeCount { get; set; }
    public decimal Revenue30D { get; set; }
    public decimal NetOutstanding { get; set; }
    public decimal HeldAdvanceMoney { get; set; }
    public int UnitsWithCredit { get; set; }
    public AssociationProfile? Profile { get; set; }
    public List<CommitteeMember> Committee { get; set; } = new();
    public List<Meeting> UpcomingMeetings { get; set; } = new();
}

public class BillingOverview
{
    public List<Payment> RecentPayments { get; set; } = new();
    public decimal AdvanceBalance { get; set; }
    public List<BillingBatch> ExistingBatches { get; set; } = new();
    public PagedResult<Invoice> Invoices { get; set; } = new();
}
