using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IPaymentRepository
{
    Task<Payment?> GetByIdAsync(int id, int tenantId);
    Task<IEnumerable<Payment>> GetByTenantIdAsync(int tenantId);
    Task<int> CreateAsync(Payment payment);
    Task<bool> UpdateStatusAsync(int id, string status, string? gatewayReference);
}
