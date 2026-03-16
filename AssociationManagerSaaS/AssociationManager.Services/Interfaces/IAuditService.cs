using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Services.Interfaces
{
    public interface IAuditService
    {
        Task LogActionAsync(int tenantId, int userId, string action, string entityName, string entityId, string? changes = null);
    }
}
