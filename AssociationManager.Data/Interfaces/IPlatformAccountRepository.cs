using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IPlatformAccountRepository
{
    Task<PlatformAccount?> GetByIdAsync(int id);
    Task<IEnumerable<PlatformAccount>> GetAllAsync();
    Task<int> CreateAsync(PlatformAccount account);
    Task<bool> UpdateAsync(PlatformAccount account);
    Task<bool> DeleteAsync(int id);
}
