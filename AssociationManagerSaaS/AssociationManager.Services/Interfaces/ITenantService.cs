using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Services.Interfaces
{
    public interface ITenantService
    {
        Task<Tenant?> GetByIdAsync(int id);
        Task<Tenant?> GetByIdentifierAsync(string identifier);
        Task<IEnumerable<Tenant>> GetAllActiveAsync();
        Task<int> CreateTenantAsync(Tenant tenant);
        Task<IEnumerable<Tenant>> GetUserTenantsAsync(int userId);
    }
}
