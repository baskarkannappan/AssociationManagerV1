using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(int id);
    Task<User?> GetByGoogleIdAsync(string googleId);
    Task<User?> GetByEmailAsync(string email);
    Task<IEnumerable<User>> GetByTenantIdAsync(int tenantId);
    Task<int> CreateAsync(User user);
    Task<bool> UpdateAsync(User user);
    Task<bool> IsUserInTenantAsync(int userId, int tenantId);
    Task<bool> AddUserToTenantAsync(int userId, int tenantId, string role);
    Task<string?> GetRoleInTenantAsync(int userId, int tenantId);
    Task<bool> RemoveUserFromTenantAsync(int userId, int tenantId);
    Task<bool> IsUserAuthorisedForAssociationAsync(int userId, int tenantId, int associationId);
    Task<IEnumerable<User>> GetByAssociationIdAsync(int associationId);
    Task<IEnumerable<User>> GetAllAsync();
    Task<bool> DeleteUserGlobalAsync(int userId);
}
