using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class CommunicationsService : ICommunicationsService
{
    private readonly IBroadcastRepository _broadcastRepository;
    private readonly ITenantContext _tenantContext;

    public CommunicationsService(IBroadcastRepository broadcastRepository, ITenantContext tenantContext)
    {
        _broadcastRepository = broadcastRepository;
        _tenantContext = tenantContext;
    }

    public async Task<Broadcast?> GetBroadcastByIdAsync(int id)
    {
        return await _broadcastRepository.GetByIdAsync(id);
    }

    public async Task<IEnumerable<Broadcast>> GetAllBroadcastsAsync()
    {
        return await _broadcastRepository.GetAllAsync();
    }

    public async Task<IEnumerable<Broadcast>> GetBroadcastsByAssetAsync(int assetId)
    {
        return await _broadcastRepository.GetByAssetIdAsync(assetId);
    }

    public async Task<int> CreateBroadcastAsync(Broadcast broadcast)
    {
        broadcast.TenantId = _tenantContext.TenantId;
        broadcast.CreatedBy = _tenantContext.UserId;
        return await _broadcastRepository.CreateAsync(broadcast);
    }

    public async Task<bool> DeleteBroadcastAsync(int id)
    {
        return await _broadcastRepository.DeleteAsync(id);
    }
}
