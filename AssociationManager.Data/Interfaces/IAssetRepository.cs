using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IAssetRepository
{
    Task<Asset?> GetByIdAsync(int id, int tenantId);
    Task<IEnumerable<Asset>> GetByParentIdAsync(int? parentId, int tenantId);
    Task<IEnumerable<Asset>> GetHierarchyAsync(int tenantId);
    Task<int> CreateAsync(Asset asset);
    Task<bool> UpdateAsync(Asset asset);
    Task<bool> DeleteAsync(int id, int tenantId);
}
