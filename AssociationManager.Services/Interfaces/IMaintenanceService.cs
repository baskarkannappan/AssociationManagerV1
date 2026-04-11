using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IMaintenanceService
{
    /// <summary>
    /// Archives audit logs older than the specified retention period in days.
    /// </summary>
    /// <param name="retentionDays">Number of days to keep in active table (Default: 180).</param>
    /// <returns>The number of records archived.</returns>
    Task<int> ArchiveAuditLogsAsync(int retentionDays = 180);
}
