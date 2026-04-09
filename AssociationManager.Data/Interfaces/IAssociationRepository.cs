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
    Task<bool> DeleteAsync(int id);
    Task<IEnumerable<Association>> GetByUserIdAsync(int userId);
    Task<bool> UpdateStatusAsync(int id, string status);
    Task<IEnumerable<Association>> GetAllAsync();
    
    // Bank Details
    Task<AssociationBankDetails?> GetBankDetailsAsync(int associationId, int tenantId);
    Task<bool> UpsertBankDetailsAsync(AssociationBankDetails details);
}
