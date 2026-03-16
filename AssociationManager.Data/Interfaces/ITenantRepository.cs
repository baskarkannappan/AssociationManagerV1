using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface ITenantRepository
{
    Task<Tenant?> GetByIdAsync(int id);
    Task<IEnumerable<Tenant>> GetAllAsync();
    Task<int> CreateAsync(Tenant tenant);
    Task<bool> UpdateAsync(Tenant tenant);
}
