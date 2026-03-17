using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface IOperationsService
{
    Task<WorkOrder?> GetWorkOrderByIdAsync(int id);
    Task<IEnumerable<WorkOrder>> GetAllWorkOrdersAsync();
    Task<IEnumerable<WorkOrder>> GetWorkOrdersByAssetIdAsync(int assetId);
    Task<int> CreateWorkOrderAsync(WorkOrder workOrder);
    Task<bool> UpdateWorkOrderAsync(WorkOrder workOrder);
    Task<bool> UpdateWorkOrderStatusAsync(int id, string status);
    Task<bool> DeleteWorkOrderAsync(int id);
}
