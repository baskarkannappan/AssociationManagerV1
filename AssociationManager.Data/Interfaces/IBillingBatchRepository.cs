using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IBillingBatchRepository
{
    Task<BillingBatch?> GetByIdAsync(int id, int tenantId, int? associationId);
    Task<BillingBatch?> GetDraftBatchAsync(int associationId, int month, int year, int tenantId);
    Task<IEnumerable<BillingBatch>> GetByAssociationAsync(int associationId, int tenantId);
    Task<int> CreateAsync(BillingBatch batch);
    Task<bool> UpdateStatusAsync(int id, string status, int tenantId, int? associationId);
    Task<bool> UpdateTotalsAsync(int id, decimal totalAmount, int invoicesGenerated, int tenantId, int associationId);
    Task<bool> BulkCommitAsync(int batchId, int tenantId, int associationId);
    Task<bool> DeleteBatchAsync(int batchId, int tenantId, int associationId);
}
