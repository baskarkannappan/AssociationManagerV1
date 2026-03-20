using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class WorkOrderRepository : IWorkOrderRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public WorkOrderRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<WorkOrder?> GetByIdAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<WorkOrder>(
            "assoc.sp_WorkOrders_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<WorkOrder>> GetAllAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<WorkOrder>(
            "assoc.sp_WorkOrders_GetAll", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<WorkOrder>> GetByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<WorkOrder>(
            "assoc.sp_WorkOrders_GetByAssetId", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(WorkOrder workOrder)
    {
        workOrder.TenantId = _tenantContext.TenantId;
        workOrder.AssociationId = _tenantContext.AssociationId;
        workOrder.CreatedBy = _tenantContext.UserId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_WorkOrders_Create", 
            new 
            { 
                workOrder.TenantId, 
                workOrder.AssociationId, 
                workOrder.AssetId, 
                workOrder.Title, 
                workOrder.Description, 
                workOrder.Priority, 
                workOrder.Status, 
                workOrder.CreatedDate, 
                workOrder.CreatedBy, 
                workOrder.AssignedTo 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(WorkOrder workOrder)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_WorkOrders_Update", 
            new 
            { 
                workOrder.WorkOrderId,
                workOrder.TenantId, 
                workOrder.AssociationId, 
                workOrder.AssetId, 
                workOrder.Title, 
                workOrder.Description, 
                workOrder.Priority, 
                workOrder.Status, 
                workOrder.AssignedTo, 
                workOrder.CompletedDate 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_WorkOrders_UpdateStatus", 
            new { Id = id, Status = status, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_WorkOrders_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
