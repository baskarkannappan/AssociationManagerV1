using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Data.Interfaces
{
    public interface IAssociationRepository
    {
        Task<IEnumerable<Association>> GetByTenantIdAsync(int tenantId);
        Task<Association?> GetByIdAsync(int id, int tenantId);
        Task<int> CreateAsync(Association association);
        Task UpdateAsync(Association association);
        Task DeleteAsync(int id, int tenantId);
    }
}
