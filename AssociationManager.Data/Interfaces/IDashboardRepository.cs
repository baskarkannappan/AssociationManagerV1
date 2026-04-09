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
}
