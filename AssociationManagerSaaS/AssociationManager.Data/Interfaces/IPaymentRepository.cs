using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Data.Interfaces
{
    public interface IPaymentRepository
    {
        Task<int> CreateAsync(Payment payment);
        Task<IEnumerable<Payment>> GetByTenantIdAsync(int tenantId);
        Task<Payment?> GetByIdAsync(int id, int tenantId);
        Task UpdateStatusAsync(int id, string status);
    }
}
