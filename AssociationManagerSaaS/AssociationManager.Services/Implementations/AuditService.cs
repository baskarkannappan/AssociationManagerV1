using System.Threading.Tasks;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Services.Interfaces;

namespace AssociationManager.Services.Implementations
{
    public class AuditService : IAuditService
    {
        private readonly IAuditLogRepository _repository;

        public AuditService(IAuditLogRepository repository)
        {
            _repository = repository;
        }

        public async Task LogActionAsync(int tenantId, int userId, string action, string entityName, string entityId, string? changes = null)
        {
            var log = new AuditLog
            {
                TenantId = tenantId,
                UserId = userId,
                Action = action,
                EntityName = entityName,
                EntityId = entityId,
                Changes = changes
            };
            await _repository.CreateAsync(log);
        }
    }
}
