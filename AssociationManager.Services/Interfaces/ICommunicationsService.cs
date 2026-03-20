using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface ICommunicationsService
{
    Task<Broadcast?> GetBroadcastByIdAsync(int id, int? associationId = null);
    Task<IEnumerable<Broadcast>> GetAllBroadcastsAsync(int? associationId = null);
    Task<IEnumerable<Broadcast>> GetBroadcastsByAssetAsync(int assetId);
    Task<int> CreateBroadcastAsync(Broadcast broadcast);
    Task<bool> DeleteBroadcastAsync(int id, int? associationId = null);
}
