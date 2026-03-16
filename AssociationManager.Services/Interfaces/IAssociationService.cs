using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IAssociationService
{
    Task<Association?> GetByIdAsync(int id);
    Task<IEnumerable<Association>> GetAllByTenantAsync();
    Task<int> CreateAsync(Association association);
    Task<bool> UpdateAsync(Association association);
    Task<bool> DeleteAsync(int id);
}
