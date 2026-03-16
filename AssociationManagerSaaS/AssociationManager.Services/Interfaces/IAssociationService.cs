using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Services.Interfaces
{
    public interface IAssociationService
    {
        Task<IEnumerable<Association>> GetAssociationsAsync(int tenantId);
        Task<Association?> GetAsync(int id, int tenantId);
        Task<int> CreateAsync(Association association);
        Task UpdateAsync(Association association);
        Task DeleteAsync(int id, int tenantId);
    }
}
