using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IPaymentRepository
{
    Task<Payment?> GetByIdAsync(int id, int tenantId, int? associationId);
    Task<IEnumerable<Payment>> GetByTenantIdAsync(int tenantId, int? associationId);
    Task<int> CreateAsync(Payment payment);
    Task<bool> UpdateStatusAsync(int id, string status, string? gatewayReference, int tenantId, int? associationId);
    Task<bool> AutoSettleAsync(int assetId, int tenantId, int associationId, int userId);
    Task<(decimal TotalOutstanding, decimal TotalCredits, int UnitsWithCredit)> GetAssociationSummaryAsync(int tenantId, int associationId);
    Task<IEnumerable<AdvancePaymentHistory>> GetAdvancesAsync(int tenantId, int associationId, int? userId = null, int? assetId = null);
}
