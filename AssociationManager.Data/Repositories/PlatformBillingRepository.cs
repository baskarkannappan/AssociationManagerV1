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
}
