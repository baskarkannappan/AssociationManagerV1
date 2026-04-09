using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _dashboardRepository;
    private readonly ITenantContext _tenantContext;

    public DashboardService(IDashboardRepository dashboardRepository, ITenantContext tenantContext)
    {
        _dashboardRepository = dashboardRepository;
        _tenantContext = tenantContext;
    }

    public async Task<int> GetTotalMembersAsync()
    {
        return await _dashboardRepository.GetTotalMembersAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<int> GetCommitteeCountAsync()
    {
        return await _dashboardRepository.GetCommitteeCountAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<decimal> GetRevenue30DAsync()
    {
        return await _dashboardRepository.GetRevenue30DAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<decimal> GetNetOutstandingAsync()
    {
        return await _dashboardRepository.GetNetOutstandingAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<(decimal amount, int units)> GetHeldAdvanceMoneyAsync()
    {
        return await _dashboardRepository.GetHeldAdvanceMoneyAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }
}
