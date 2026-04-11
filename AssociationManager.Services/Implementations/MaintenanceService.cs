using AssociationManager.Data;
using AssociationManager.Services.Interfaces;
using Dapper;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class MaintenanceService : IMaintenanceService
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public MaintenanceService(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<int> ArchiveAuditLogsAsync(int retentionDays = 180)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_Maintenance_ArchiveAuditLogs",
            new { RetentionDays = retentionDays, BatchSize = 5000 },
            commandType: CommandType.StoredProcedure);
    }
}
