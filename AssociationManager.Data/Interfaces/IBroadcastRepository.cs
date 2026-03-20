using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IBroadcastRepository
{
    Task<Broadcast?> GetByIdAsync(int id, int tenantId, int? associationId);
    Task<IEnumerable<Broadcast>> GetAllAsync(int tenantId, int? associationId);
    Task<IEnumerable<Broadcast>> GetByAssetIdAsync(int assetId, int tenantId, int? associationId);
    Task<int> CreateAsync(Broadcast broadcast);
    Task<bool> DeleteAsync(int id, int tenantId, int? associationId);
}
