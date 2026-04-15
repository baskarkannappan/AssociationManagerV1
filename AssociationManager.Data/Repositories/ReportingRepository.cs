using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class ReportingRepository : IReportingRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public ReportingRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<FinancialMetricsReport> GetFinancialMetricsAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var report = new FinancialMetricsReport();

        using var multi = await connection.QueryMultipleAsync(
            "assoc.sp_Reports_GetFinancialMetrics",
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);

        // 1. Aging Buckets
        var agingRow = await multi.ReadFirstOrDefaultAsync<dynamic>();
        if (agingRow != null)
        {
            report.Aging = new AgingReport
            {
                Current = agingRow.Bucket0_30,
                Bucket31_60 = agingRow.Bucket31_60,
                Bucket61_90 = agingRow.Bucket61_90,
                Over90 = agingRow.BucketOver90
            };
        }

        // 2. Monthly Collection Efficiency
        report.MonthlyEfficiency = (await multi.ReadAsync<MonthlyCollectionEfficiency>()).ToList();

        // 3. High Level Stats
        var statsRow = await multi.ReadFirstOrDefaultAsync<dynamic>();
        if (statsRow != null)
        {
            report.TotalCollectedAllTime = statsRow.TotalCollectedAllTime;
            report.TotalPortfolioOutstanding = statsRow.TotalUnpaidPrincipal;
        }

        return report;
    }

    public async Task<FinancialMetricsReport> GetFinancialMetricsV2Async(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var report = new FinancialMetricsReport();

        using var multi = await connection.QueryMultipleAsync(
            "assoc.sp_Reports_GetFinancialMetrics_v2",
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);

        // 1. Aging Buckets
        var agingRow = await multi.ReadFirstOrDefaultAsync<dynamic>();
        if (agingRow != null)
        {
            report.Aging = new AgingReport
            {
                Current = agingRow.Bucket0_30,
                Bucket31_60 = agingRow.Bucket31_60,
                Bucket61_90 = agingRow.Bucket61_90,
                Over90 = agingRow.BucketOver90
            };
        }

        // 2. Monthly Collection Efficiency
        report.MonthlyEfficiency = (await multi.ReadAsync<MonthlyCollectionEfficiency>()).ToList();

        // 3. High Level Stats
        var statsRow = await multi.ReadFirstOrDefaultAsync<dynamic>();
        if (statsRow != null)
        {
            report.TotalCollectedAllTime = statsRow.TotalCollectedAllTime;
            report.TotalPortfolioOutstanding = statsRow.TotalUnpaidPrincipal;
        }

        return report;
    }
}
