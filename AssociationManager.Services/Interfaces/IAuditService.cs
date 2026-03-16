using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IAuditService
{
    Task LogAsync(string action, string? entity = null, int? entityId = null);
    Task<IEnumerable<AuditLog>> GetLogsAsync();
}
