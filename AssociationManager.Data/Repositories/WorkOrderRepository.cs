using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
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

    public async Task<WorkOrder?> GetByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<WorkOrder>(
            @"SELECT w.*, a.Name as AssetName 
              FROM WorkOrders w 
              LEFT JOIN Assets a ON w.AssetId = a.AssetId
              WHERE w.WorkOrderId = @Id AND w.TenantId = @TenantId", 
            new { Id = id, TenantId = _tenantContext.TenantId });
    }

    public async Task<IEnumerable<WorkOrder>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<WorkOrder>(
            @"SELECT w.*, a.Name as AssetName 
              FROM WorkOrders w 
              LEFT JOIN Assets a ON w.AssetId = a.AssetId
              WHERE w.TenantId = @TenantId 
              ORDER BY w.CreatedDate DESC", 
            new { TenantId = _tenantContext.TenantId });
    }

    public async Task<IEnumerable<WorkOrder>> GetByAssetIdAsync(int assetId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<WorkOrder>(
            @"SELECT w.*, a.Name as AssetName 
              FROM WorkOrders w 
              LEFT JOIN Assets a ON w.AssetId = a.AssetId
              WHERE w.AssetId = @AssetId AND w.TenantId = @TenantId", 
            new { AssetId = assetId, TenantId = _tenantContext.TenantId });
    }

    public async Task<int> CreateAsync(WorkOrder workOrder)
    {
        workOrder.TenantId = _tenantContext.TenantId;
        workOrder.CreatedBy = _tenantContext.UserId;
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"INSERT INTO WorkOrders (TenantId, AssetId, Title, Description, Priority, Status, CreatedDate, CreatedBy, AssignedTo) 
                       OUTPUT INSERTED.WorkOrderId 
                       VALUES (@TenantId, @AssetId, @Title, @Description, @Priority, @Status, @CreatedDate, @CreatedBy, @AssignedTo)";
        return await connection.ExecuteScalarAsync<int>(sql, workOrder);
    }

    public async Task<bool> UpdateAsync(WorkOrder workOrder)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"UPDATE WorkOrders 
                       SET AssetId = @AssetId, Title = @Title, Description = @Description, 
                           Priority = @Priority, Status = @Status, AssignedTo = @AssignedTo, 
                           CompletedDate = @CompletedDate
                       WHERE WorkOrderId = @WorkOrderId AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, new { 
            workOrder.AssetId, workOrder.Title, workOrder.Description, 
            workOrder.Priority, workOrder.Status, workOrder.AssignedTo, 
            workOrder.CompletedDate, workOrder.WorkOrderId, TenantId = _tenantContext.TenantId 
        });
        return affectedRows > 0;
    }

    public async Task<bool> UpdateStatusAsync(int id, string status)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE WorkOrders SET Status = @Status WHERE WorkOrderId = @Id AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, Status = status, TenantId = _tenantContext.TenantId });
        return affectedRows > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "DELETE FROM WorkOrders WHERE WorkOrderId = @Id AND TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, TenantId = _tenantContext.TenantId });
        return affectedRows > 0;
    }
}
