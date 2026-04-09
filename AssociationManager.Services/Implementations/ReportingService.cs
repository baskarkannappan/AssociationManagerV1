using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class ReportingService : IReportingService
{
    private readonly IReportingRepository _reportingRepository;
    private readonly ITenantContext _tenantContext;

    public ReportingService(IReportingRepository reportingRepository, ITenantContext tenantContext)
    {
        _reportingRepository = reportingRepository;
        _tenantContext = tenantContext;
    }

    public async Task<FinancialMetricsReport> GetFinancialMetricsAsync()
    {
        return await _reportingRepository.GetFinancialMetricsAsync(_tenantContext.TenantId, _tenantContext.AssociationId);
    }
}
