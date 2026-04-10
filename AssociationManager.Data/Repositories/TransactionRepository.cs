using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class TransactionRepository : ITransactionRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public TransactionRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<long> CreateTransactionAsync(Transaction transaction)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<long>(
            "assoc.sp_Transactions_Create", 
            new 
            { 
                transaction.TenantId, 
                transaction.AssociationId, 
                transaction.AssetId, 
                transaction.InvoiceId, 
                transaction.PaymentId, 
                transaction.Type, 
                transaction.Amount, 
                transaction.Category, 
                transaction.Description, 
                transaction.TransactionDate 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Transaction>> GetByAssetIdAsync(int? assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Transaction>(
            "assoc.sp_Transactions_GetByAssetId", 
            new { assetId, tenantId, associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Transaction>> GetByTenantIdAsync(int tenantId, int associationId, DateTime? startDate = null, DateTime? endDate = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Transaction>(
            "assoc.sp_Transactions_GetByTenantId", 
            new { tenantId, associationId, startDate, endDate },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Transaction>> GetByInvoiceIdAsync(int invoiceId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Transaction>(
            "SELECT * FROM assoc.Transactions WHERE InvoiceId = @InvoiceId AND TenantId = @TenantId AND AssociationId = @AssociationId ORDER BY TransactionDate DESC", 
            new { invoiceId, tenantId, associationId });
    }

    public async Task<decimal> GetBalanceByAssetIdAsync(int? assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<decimal>(
            "assoc.sp_Transactions_GetBalanceByAssetId", 
            new { assetId, tenantId, associationId },
            commandType: CommandType.StoredProcedure);
    }
}
