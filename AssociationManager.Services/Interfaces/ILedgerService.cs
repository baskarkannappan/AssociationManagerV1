using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface ILedgerService
{
    Task<long> RecordTransactionAsync(Transaction transaction);
    Task<decimal> GetAssetBalanceAsync(int assetId);
    Task<IEnumerable<Transaction>> GetAssetTransactionsAsync(int assetId);
    Task<IEnumerable<Transaction>> GetTenantTransactionsAsync(DateTime? start = null, DateTime? end = null);
}
