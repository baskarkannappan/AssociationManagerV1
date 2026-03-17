using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IBroadcastRepository
{
    Task<Broadcast?> GetByIdAsync(int id);
    Task<IEnumerable<Broadcast>> GetAllAsync();
    Task<int> CreateAsync(Broadcast broadcast);
    Task<bool> DeleteAsync(int id);
}
