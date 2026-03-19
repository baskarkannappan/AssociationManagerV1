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
        transaction.TenantId = transaction.TenantId; // Ensure it's set
        transaction.AssociationId = transaction.AssociationId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<long>(
            "sp_Transactions_Create", 
            transaction,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Transaction>> GetByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Transaction>(
            "sp_Transactions_GetByAssetId", 
            new { assetId, tenantId, associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Transaction>> GetByTenantIdAsync(int tenantId, int associationId, DateTime? startDate = null, DateTime? endDate = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Transaction>(
            "sp_Transactions_GetByTenantId", 
            new { tenantId, associationId, startDate, endDate },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<decimal> GetBalanceByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<decimal>(
            "sp_Transactions_GetBalanceByAssetId", 
            new { assetId, tenantId, associationId },
            commandType: CommandType.StoredProcedure);
    }
}
