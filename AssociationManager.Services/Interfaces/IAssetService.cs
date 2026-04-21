using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IAssetService
{
    Task<Asset?> GetByIdAsync(int id);
    Task<IEnumerable<Asset>> GetAllAsync();
    Task<IEnumerable<Asset>> GetHierarchyAsync(int? userId = null, int? parentId = null);
    Task<int> CreateAsync(Asset asset);
    Task<int> BulkCreateAsync(BulkCreateRequest request);
    Task ProcessBulkCreateJobAsync(int tenantId, int associationId, int userId, BulkCreateRequest request);
    Task<bool> UpdateAsync(Asset asset);
    Task<bool> DeleteAsync(int id);
    Task<IEnumerable<dynamic>> GetAssignedTariffsAsync(int assetId);
}
