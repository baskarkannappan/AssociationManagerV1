using System.Threading.Tasks;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Services.Interfaces;

namespace AssociationManager.Services.Implementations
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _repository;

        public UserService(IUserRepository repository)
        {
            _repository = repository;
        }

        public async Task<User?> GetByEmailAsync(string email)
        {
            return await _repository.GetByEmailAsync(email);
        }

        public async Task<User> CreateOrUpdateGoogleUserAsync(string email, string name, string googleId)
        {
            var user = await _repository.GetByEmailAsync(email);
            if (user == null)
            {
                user = new User
                {
                    Email = email,
                    FullName = name,
                    GoogleId = googleId,
                    IsActive = true
                };
                user.Id = await _repository.CreateAsync(user);
            }
            else
            {
                user.FullName = name;
                user.GoogleId = googleId;
                await _repository.UpdateAsync(user);
            }
            return user;
        }
    }
}
