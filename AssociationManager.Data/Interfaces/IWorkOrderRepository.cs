using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IWorkOrderRepository
{
    Task<WorkOrder?> GetByIdAsync(int id, int tenantId, int associationId);
    Task<IEnumerable<WorkOrder>> GetAllAsync(int tenantId, int associationId);
    Task<IEnumerable<WorkOrder>> GetByAssetIdAsync(int assetId, int tenantId, int associationId);
    Task<int> CreateAsync(WorkOrder workOrder);
    Task<bool> UpdateAsync(WorkOrder workOrder);
    Task<bool> UpdateStatusAsync(int id, string status, int tenantId, int associationId);
    Task<bool> DeleteAsync(int id, int tenantId, int associationId);
}
