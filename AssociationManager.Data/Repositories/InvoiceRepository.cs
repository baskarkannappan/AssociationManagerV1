using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class InvoiceRepository : IInvoiceRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public InvoiceRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Invoice?> GetByIdAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Invoice>(
            "assoc.sp_Invoices_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Invoice>> GetAllAsync(int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Invoice>(
            "assoc.sp_Invoices_GetAll", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Invoice>> GetByAssetIdAsync(int assetId, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Invoice>(
            "assoc.sp_Invoices_GetByAssetId", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Invoice invoice)
    {
        invoice.TenantId = _tenantContext.TenantId;
        invoice.AssociationId = _tenantContext.AssociationId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Invoices_Create", 
            new 
            { 
                invoice.TenantId, 
                invoice.AssociationId, 
                invoice.AssetId, 
                invoice.BillingBatchId,
                invoice.Title, 
                invoice.Description, 
                invoice.Amount, 
                invoice.DueDate, 
                invoice.Status, 
                invoice.CreatedDate 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Invoices_UpdateStatus", 
            new { Id = id, Status = status, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Invoices_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<InvoiceLineItem>> GetLineItemsAsync(int invoiceId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<InvoiceLineItem>(
            "assoc.sp_InvoiceLineItems_GetByInvoiceId",
            new { InvoiceId = invoiceId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateLineItemAsync(InvoiceLineItem lineItem)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_InvoiceLineItems_Create",
            new
            {
                lineItem.InvoiceId,
                lineItem.ChargeName,
                lineItem.Amount,
                lineItem.Description,
                lineItem.TariffLayerId,
                lineItem.Rate
            },
            commandType: CommandType.StoredProcedure);
    }
}
