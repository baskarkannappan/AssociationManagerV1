using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _dashboardRepository;
    private readonly IFinanceService _financeService;
    private readonly ITenantContext _tenantContext;
    private readonly IAssociationRepository _associationRepository;

    public DashboardService(
        IDashboardRepository dashboardRepository, 
        IFinanceService financeService,
        ITenantContext tenantContext,
        IAssociationRepository associationRepository)
    {
        _dashboardRepository = dashboardRepository;
        _financeService = financeService;
        _tenantContext = tenantContext;
        _associationRepository = associationRepository;
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
        // Use FinanceService for current outstanding balance to ensure late fines are included (Smart Sum)
        var summary = await _financeService.GetFinanceSummaryAsync(_tenantContext.AssociationId);
        return summary.TotalUnpaid;
    }

    public async Task<(decimal amount, int units)> GetHeldAdvanceMoneyAsync()
    {
        return await _dashboardRepository.GetHeldAdvanceMoneyAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }
}
