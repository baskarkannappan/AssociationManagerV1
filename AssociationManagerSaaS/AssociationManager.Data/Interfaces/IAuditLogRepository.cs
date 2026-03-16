using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Data.Interfaces
{
    public interface IAuditLogRepository
    {
        Task<int> CreateAsync(AuditLog log);
        Task<IEnumerable<AuditLog>> GetByTenantIdAsync(int tenantId);
    }
}
