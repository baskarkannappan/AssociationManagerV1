using AssociationManager.Shared.Models;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IReportingService
{
    Task<FinancialMetricsReport> GetFinancialMetricsAsync();
    Task<FinancialMetricsReport> GetFinancialMetricsV2Async();
}
