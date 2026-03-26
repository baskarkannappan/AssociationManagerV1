using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IAuditService
{
    Task LogAsync(string action, string? entity = null, int? entityId = null, int? associationId = null, int? assetId = null);
    Task<IEnumerable<AuditLog>> GetLogsAsync();
    Task<IEnumerable<AuditLog>> GetAssetLogsAsync(int assetId);
}
