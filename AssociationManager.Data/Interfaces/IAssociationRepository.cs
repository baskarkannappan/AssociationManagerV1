using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IAssociationRepository
{
    Task<Association?> GetByIdAsync(int id, int tenantId);
    Task<IEnumerable<Association>> GetAllByTenantIdAsync(int tenantId);
    Task<int> CreateAsync(Association association);
    Task<bool> UpdateAsync(Association association);
    Task<bool> DeleteAsync(int id, int tenantId);
    Task<IEnumerable<Association>> GetByUserIdAsync(int userId);
}
