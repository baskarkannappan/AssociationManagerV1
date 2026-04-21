using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IAssetRepository
{
    Task<Asset?> GetByIdAsync(int id, int tenantId, int associationId);
    Task<IEnumerable<Asset>> GetByParentIdAsync(int? parentId, int tenantId, int associationId);
    Task<IEnumerable<Asset>> GetHierarchyAsync(int tenantId, int associationId, int? parentId = null, int? userId = null);
    Task<IEnumerable<Asset>> GetAllFlatAsync(int tenantId, int associationId);
    Task<int> CreateAsync(Asset asset);
    Task<int> BulkCreateAsync(IEnumerable<Asset> assets);
    Task<bool> UpdateAsync(Asset asset);
    Task<bool> DeleteAsync(int id, int tenantId, int associationId);
    Task<int> CountAsync(int tenantId, int associationId);
    Task<IEnumerable<dynamic>> GetAssignedTariffsAsync(int assetId, int tenantId, int associationId);
}
