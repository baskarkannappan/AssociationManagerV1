using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IWorkOrderRepository
{
    Task<WorkOrder?> GetByIdAsync(int id);
    Task<IEnumerable<WorkOrder>> GetAllAsync();
    Task<IEnumerable<WorkOrder>> GetByAssetIdAsync(int assetId);
    Task<int> CreateAsync(WorkOrder workOrder);
    Task<bool> UpdateAsync(WorkOrder workOrder);
    Task<bool> UpdateStatusAsync(int id, string status);
    Task<bool> DeleteAsync(int id);
}
