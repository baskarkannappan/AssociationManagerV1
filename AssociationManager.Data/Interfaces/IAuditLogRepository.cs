using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IAuditLogRepository
{
    Task<int> CreateAsync(AuditLog log);
    Task<IEnumerable<AuditLog>> GetByTenantIdAsync(int tenantId, int associationId);
}
