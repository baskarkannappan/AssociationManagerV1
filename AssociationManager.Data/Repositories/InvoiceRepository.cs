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

    public async Task<PagedResult<Invoice>> GetPagedAsync(int tenantId, InvoiceSearchCriteria criteria)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@TenantId", tenantId);
        parameters.Add("@AssociationId", criteria.AssociationId);
        parameters.Add("@AssetId", criteria.AssetId);
        parameters.Add("@AssetIds", criteria.AssetIds != null && criteria.AssetIds.Any() ? string.Join(",", criteria.AssetIds) : null);
        parameters.Add("@SearchTerm", criteria.SearchTerm);
        parameters.Add("@Status", criteria.Status);
        parameters.Add("@StartDate", criteria.StartDate);
        parameters.Add("@EndDate", criteria.EndDate);
        parameters.Add("@PageNumber", criteria.PageNumber);
        parameters.Add("@PageSize", criteria.PageSize);
        parameters.Add("@SortColumn", criteria.SortColumn);
        parameters.Add("@SortDirection", criteria.SortDirection);

        var result = new PagedResult<Invoice>
        {
            PageNumber = criteria.PageNumber,
            PageSize = criteria.PageSize
        };

        // Execution
        var items = await connection.QueryAsync<dynamic>(
            "assoc.sp_Invoices_GetPaged", 
            parameters, 
            commandType: CommandType.StoredProcedure);

        var invoices = new List<Invoice>();
        foreach (var row in items)
        {
            if (result.TotalCount == 0)
            {
                result.TotalCount = Convert.ToInt32(row.TotalCount ?? 0);
                result.TotalUnpaid = Convert.ToDecimal(row.TotalUnpaid ?? 0m);
            }

            invoices.Add(new Invoice
            {
                InvoiceId = Convert.ToInt32(row.InvoiceId),
                TenantId = Convert.ToInt32(row.TenantId),
                AssociationId = Convert.ToInt32(row.AssociationId),
                AssetId = row.AssetId != null ? Convert.ToInt32(row.AssetId) : null,
                AssetName = row.AssetName?.ToString(),
                Title = row.Title?.ToString() ?? string.Empty,
                Description = row.Description?.ToString(),
                Amount = Convert.ToDecimal(row.Amount),
                DueDate = Convert.ToDateTime(row.DueDate),
                Status = row.Status?.ToString() ?? "Unpaid",
                CreatedDate = Convert.ToDateTime(row.CreatedDate),
                IsAdvancePaid = Convert.ToBoolean(row.IsAdvancePaid ?? 0)
            });
        }
        
        result.Items = invoices;
        result.FilteredCount = result.TotalCount; // SP currently returns total count for the filtered set

        return result;
    }

    public async Task<(decimal TotalUnpaid, decimal Collected30Days)> GetSummaryStatsAsync(int tenantId, int? associationId, int? assetId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var stats = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "assoc.sp_Finance_GetSummaryStats",
            new { TenantId = tenantId, AssociationId = associationId, AssetId = assetId },
            commandType: CommandType.StoredProcedure);

        return (stats?.TotalUnpaid ?? 0, stats?.Collected30Days ?? 0);
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
