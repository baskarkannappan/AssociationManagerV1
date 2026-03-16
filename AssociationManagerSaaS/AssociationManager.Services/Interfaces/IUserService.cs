using System.Threading.Tasks;
using AssociationManager.Shared.Models;

namespace AssociationManager.Services.Interfaces
{
    public interface IUserService
    {
        Task<User?> GetByEmailAsync(string email);
        Task<User> CreateOrUpdateGoogleUserAsync(string email, string name, string googleId);
    }
}
