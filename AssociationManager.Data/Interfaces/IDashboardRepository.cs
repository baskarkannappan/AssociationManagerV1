using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IDashboardRepository
{
    Task<int> GetTotalMembersAsync(int tenantId, int associationId);
    Task<int> GetCommitteeCountAsync(int tenantId, int associationId);
    Task<decimal> GetRevenue30DAsync(int tenantId, int associationId);
    Task<decimal> GetNetOutstandingAsync(int tenantId, int associationId);
    Task<(decimal amount, int units)> GetHeldAdvanceMoneyAsync(int tenantId, int associationId);

    /// <summary>
    /// Returns all dashboard summary metrics from the AssociationBalances snapshot table in a single query.
    /// Metrics are refreshed hourly by the background worker.
    /// </summary>
    Task<(decimal TotalRevenue, decimal NetOutstanding, decimal HeldAdvanceMoney, int UnitsWithCredit, int TotalMembers, int CommitteeCount, int PendingWorkOrders)> GetAdminSnapshotAsync(int tenantId, int associationId);
}
