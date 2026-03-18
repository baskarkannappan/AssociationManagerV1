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
        const string sql = @"INSERT INTO Transactions (TenantId, AssetId, InvoiceId, PaymentId, Type, Amount, Category, Description, TransactionDate) 
                           VALUES (@TenantId, @AssetId, @InvoiceId, @PaymentId, @Type, @Amount, @Category, @Description, @TransactionDate);
                           SELECT CAST(SCOPE_IDENTITY() as bigint)";
        return await connection.ExecuteScalarAsync<long>(sql, transaction);
    }

    public async Task<IEnumerable<Transaction>> GetByAssetIdAsync(int assetId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = "SELECT * FROM Transactions WHERE AssetId = @assetId ORDER BY TransactionDate DESC";
        return await connection.QueryAsync<Transaction>(sql, new { assetId });
    }

    public async Task<IEnumerable<Transaction>> GetByTenantIdAsync(int tenantId, DateTime? startDate = null, DateTime? endDate = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = @"SELECT * FROM Transactions 
                             WHERE TenantId = @tenantId 
                             AND (@startDate IS NULL OR TransactionDate >= @startDate)
                             AND (@endDate IS NULL OR TransactionDate <= @endDate)
                             ORDER BY TransactionDate DESC";
        return await connection.QueryAsync<Transaction>(sql, new { tenantId, startDate, endDate });
    }

    public async Task<decimal> GetBalanceByAssetIdAsync(int assetId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        const string sql = @"SELECT SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END) 
                             FROM Transactions WHERE AssetId = @assetId";
        return await connection.ExecuteScalarAsync<decimal>(sql, new { assetId });
    }
}
