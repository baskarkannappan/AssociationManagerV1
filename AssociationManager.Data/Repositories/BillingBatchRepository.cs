using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class BillingBatchRepository : IBillingBatchRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public BillingBatchRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<BillingBatch?> GetByIdAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<BillingBatch>(
            "assoc.sp_BillingBatches_GetById",
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<BillingBatch?> GetDraftBatchAsync(int associationId, int month, int year, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<BillingBatch>(
            "assoc.sp_BillingBatches_GetDraft",
            new { AssociationId = associationId, Month = month, Year = year, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<BillingBatch>> GetByAssociationAsync(int associationId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<BillingBatch>(
            "assoc.sp_BillingBatches_GetByAssociation",
            new { AssociationId = associationId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(BillingBatch batch)
    {
        if (batch.TenantId <= 0) batch.TenantId = _tenantContext.TenantId;
        if (batch.AssociationId <= 0) batch.AssociationId = _tenantContext.AssociationId;
        
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_BillingBatches_Create",
            new
            {
                batch.TenantId,
                batch.AssociationId,
                batch.Month,
                batch.Year,
                batch.Status,
                batch.TotalAmount,
                batch.InvoicesGenerated,
                batch.CreatedDate
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_BillingBatches_UpdateStatus",
            new { Id = id, Status = status, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> UpdateTotalsAsync(int id, decimal totalAmount, int invoicesGenerated, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_BillingBatches_UpdateTotals",
            new { Id = id, TotalAmount = totalAmount, InvoicesGenerated = invoicesGenerated, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> BulkCommitAsync(int batchId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        // Stored procedure has SET NOCOUNT ON, which may cause Dapper to return -1 even on success.
        return await connection.ExecuteAsync(
            "assoc.sp_Invoices_BulkCommit",
            new { BatchId = batchId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) >= -1;
    }

    public async Task<bool> DeleteBatchAsync(int batchId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_BillingBatches_Delete",
            new { BatchId = batchId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
