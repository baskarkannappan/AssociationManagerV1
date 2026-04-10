using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class LedgerService : ILedgerService
{
    private readonly ITransactionRepository _transactionRepository;
    private readonly ITenantContext _tenantContext;

    public LedgerService(ITransactionRepository transactionRepository, ITenantContext tenantContext)
    {
        _transactionRepository = transactionRepository;
        _tenantContext = tenantContext;
    }

    public async Task<long> RecordTransactionAsync(Transaction transaction)
    {
        transaction.TenantId = _tenantContext.TenantId;
        transaction.AssociationId = _tenantContext.AssociationId;
        if (transaction.TransactionDate == default)
        {
            transaction.TransactionDate = DateTime.UtcNow;
        }
        return await _transactionRepository.CreateTransactionAsync(transaction);
    }

    public async Task<decimal> GetAssetBalanceAsync(int assetId)
    {
        return await _transactionRepository.GetBalanceByAssetIdAsync(assetId, _tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<IEnumerable<Transaction>> GetAssetTransactionsAsync(int assetId)
    {
        return await _transactionRepository.GetByAssetIdAsync(assetId, _tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<IEnumerable<Transaction>> GetTransactionsByInvoiceIdAsync(int invoiceId)
    {
        return await _transactionRepository.GetByInvoiceIdAsync(invoiceId, _tenantContext.TenantId, _tenantContext.AssociationId);
    }

    public async Task<IEnumerable<Transaction>> GetTenantTransactionsAsync(DateTime? start = null, DateTime? end = null)
    {
        return await _transactionRepository.GetByTenantIdAsync(_tenantContext.TenantId, _tenantContext.AssociationId, start, end);
    }
}
