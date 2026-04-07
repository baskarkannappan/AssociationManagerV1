using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class PlatformBillingRepository : IPlatformBillingRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public PlatformBillingRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<int> CreateInvoiceAsync(PlatformInvoice invoice)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_PlatformInvoices_Insert",
            new { 
                invoice.AssociationId, 
                invoice.PlanId, 
                invoice.Amount, 
                invoice.BillingDate,
                invoice.DueDate 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<PlatformInvoice>> GetInvoicesByAssociationIdAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<PlatformInvoice>(
            "corp.sp_PlatformInvoices_GetByAssociationId",
            new { associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<PlatformInvoice>> GetAllInvoicesAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<PlatformInvoice>(
            "corp.sp_PlatformInvoices_GetAll",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> RecordPaymentAsync(PlatformPayment payment)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_PlatformPayments_Insert",
            new { 
                payment.PlatformInvoiceId, 
                payment.Amount, 
                payment.TransactionRef,
                payment.PaymentMethod,
                payment.Status
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateInvoiceStatusAsync(int invoiceId, string status)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_PlatformInvoices_UpdateStatus",
            new { PlatformInvoiceId = invoiceId, Status = status },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<decimal> GetRevenueAsync(DateTime startDate, DateTime endDate)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<decimal>(
            "corp.sp_PlatformPayments_GetRevenue", 
            new { startDate, endDate },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<decimal> GetWalletBalanceAsync(int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<decimal>(
            "corp.sp_Associations_GetWalletBalance",
            new { associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateWalletBalanceAsync(int associationId, decimal delta)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Associations_UpdateWalletBalance",
            new { associationId, delta },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<int> RecordAdvancePaymentAsync(PlatformAdvanceHistory advance)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_PlatformAdvancePayments_Insert",
            new { 
                advance.AssociationId, 
                advance.Amount, 
                advance.Status,
                advance.TransactionRef,
                advance.Description,
                advance.Notes
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<PagedResult<PlatformAdvanceHistory>> GetPagedAdvanceHistoryAsync(int associationId, AdvanceSearchCriteria criteria)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AssociationId", associationId);
        parameters.Add("@SearchTerm", criteria.SearchTerm);
        parameters.Add("@Status", criteria.Status);
        parameters.Add("@StartDate", criteria.StartDate);
        parameters.Add("@EndDate", criteria.EndDate);
        parameters.Add("@PageNumber", criteria.PageNumber);
        parameters.Add("@PageSize", criteria.PageSize);
        parameters.Add("@SortColumn", criteria.SortColumn);
        parameters.Add("@SortDirection", criteria.SortDirection);

        var result = await connection.QueryAsync<PlatformAdvanceHistory>(
            "corp.sp_PlatformAdvancePayments_GetPaged",
            parameters,
            commandType: CommandType.StoredProcedure);

        // Map TotalCount from first item
        var history = result.ToList();
        var totalCount = history.Any() ? history.First().TotalCount : 0;
        
        return new PagedResult<PlatformAdvanceHistory> { Items = history, TotalCount = totalCount };
    }
}
