using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class RazorpayRepository : IRazorpayRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public RazorpayRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<TenantPaymentConfig?> GetPaymentConfigAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<TenantPaymentConfig>(
            "corp.sp_TenantPaymentConfig_GetByTenantId",
            new { TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateOrderAsync(PaymentOrder order)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_PaymentOrders_Create",
            new
            {
                order.TenantId,
                order.AssociationId,
                order.UserId,
                order.RazorpayOrderId,
                order.Amount,
                order.Currency,
                order.InvoiceId,
                order.AssetId,
                order.Receipt,
                order.PrimaryAccountName,
                order.PrimaryAccountNumber
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<PaymentOrder?> GetOrderByRazorpayIdAsync(string razorpayOrderId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<PaymentOrder>(
            "assoc.sp_PaymentOrders_GetByOrderId",
            new { RazorpayOrderId = razorpayOrderId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateOrderStatusAsync(string razorpayOrderId, string status, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_PaymentOrders_UpdateStatus",
            new { RazorpayOrderId = razorpayOrderId, Status = status, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<int> CreateTransactionAsync(PaymentTransaction transaction)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_PaymentTransactions_Create",
            new
            {
                transaction.TenantId,
                transaction.AssociationId,
                transaction.PaymentOrderId,
                transaction.RazorpayPaymentId,
                transaction.RazorpayOrderId,
                transaction.RazorpaySignature,
                transaction.Status,
                transaction.Amount,
                transaction.RawResponse,
                transaction.PrimaryAccountName,
                transaction.PrimaryAccountNumber,
                transaction.PaymentMethod,
                transaction.BankName,
                transaction.BankRrn,
                transaction.CardNetwork,
                transaction.GatewayFee,
                transaction.GatewayTax
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateWebhookLogAsync(PaymentWebhookLog log)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_PaymentWebhookLogs_Create",
            new
            {
                log.TenantId,
                log.EventType,
                log.RawPayload,
                log.Signature
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<PaymentHistoryItem>> GetTransactionsByInvoiceIdAsync(int invoiceId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<PaymentHistoryItem>(
            "assoc.sp_PaymentTransactions_GetByInvoiceId",
            new { InvoiceId = invoiceId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<PaymentOrder>> GetOrdersByInvoiceIdAsync(int invoiceId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<PaymentOrder>(
            "assoc.sp_PaymentOrders_GetByInvoiceId",
            new { InvoiceId = invoiceId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> TransactionExistsAsync(string razorpayPaymentId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "assoc.sp_PaymentTransactions_CheckExists",
            new { RazorpayPaymentId = razorpayPaymentId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }
}
