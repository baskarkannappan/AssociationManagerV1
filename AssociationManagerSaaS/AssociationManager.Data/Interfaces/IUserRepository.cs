using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Data.Interfaces
{
    public interface IUserRepository
    {
        Task<User?> GetByIdAsync(int id);
        Task<User?> GetByEmailAsync(string email);
        Task<int> CreateAsync(User user);
        Task UpdateAsync(User user);
        Task AddToTenantAsync(int userId, int tenantId);
    }
}
