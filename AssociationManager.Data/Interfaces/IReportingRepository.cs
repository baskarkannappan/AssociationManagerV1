using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IReportingRepository
{
    Task<FinancialMetricsReport> GetFinancialMetricsAsync(int tenantId, int associationId);
    Task<FinancialMetricsReport> GetFinancialMetricsV2Async(int tenantId, int associationId);
}
