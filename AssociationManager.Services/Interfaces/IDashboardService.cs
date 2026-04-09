using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IDashboardService
{
    Task<int> GetTotalMembersAsync();
    Task<int> GetCommitteeCountAsync();
    Task<decimal> GetRevenue30DAsync();
    Task<decimal> GetNetOutstandingAsync();
    Task<(decimal amount, int units)> GetHeldAdvanceMoneyAsync();
}
