using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class OperationsService : IOperationsService
{
    private readonly IWorkOrderRepository _workOrderRepository;
    private readonly ITenantContext _tenantContext;

    public OperationsService(IWorkOrderRepository workOrderRepository, ITenantContext tenantContext)
    {
        _workOrderRepository = workOrderRepository;
        _tenantContext = tenantContext;
    }

    public async Task<WorkOrder?> GetWorkOrderByIdAsync(int id)
    {
        return await _workOrderRepository.GetByIdAsync(id);
    }

    public async Task<IEnumerable<WorkOrder>> GetAllWorkOrdersAsync()
    {
        return await _workOrderRepository.GetAllAsync();
    }

    public async Task<IEnumerable<WorkOrder>> GetWorkOrdersByAssetIdAsync(int assetId)
    {
        return await _workOrderRepository.GetByAssetIdAsync(assetId);
    }

    public async Task<int> CreateWorkOrderAsync(WorkOrder workOrder)
    {
        workOrder.TenantId = _tenantContext.TenantId;
        workOrder.CreatedBy = _tenantContext.UserId;
        return await _workOrderRepository.CreateAsync(workOrder);
    }

    public async Task<bool> UpdateWorkOrderAsync(WorkOrder workOrder)
    {
        workOrder.TenantId = _tenantContext.TenantId;
        return await _workOrderRepository.UpdateAsync(workOrder);
    }

    public async Task<bool> UpdateWorkOrderStatusAsync(int id, string status)
    {
        return await _workOrderRepository.UpdateStatusAsync(id, status);
    }

    public async Task<bool> DeleteWorkOrderAsync(int id)
    {
        return await _workOrderRepository.DeleteAsync(id);
    }
}
