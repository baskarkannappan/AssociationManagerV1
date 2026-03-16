using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Data.Interfaces
{
    public interface ITenantRepository
    {
        Task<Tenant?> GetByIdAsync(int id);
        Task<Tenant?> GetByIdentifierAsync(string identifier);
        Task<IEnumerable<Tenant>> GetAllAsync();
        Task<int> CreateAsync(Tenant tenant);
        Task UpdateAsync(Tenant tenant);
        Task<IEnumerable<Tenant>> GetByUserIdAsync(int userId);
    }
}
