using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class CorporateDashboardMetrics
{
    public int TotalAssociations { get; set; }
    public int TotalUsers { get; set; }
    public IEnumerable<AuditLog> RecentActivities { get; set; } = new List<AuditLog>();
}
