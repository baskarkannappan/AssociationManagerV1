using System.Threading.Tasks;
using AssociationManager.Shared.DTOs;

namespace AssociationManager.Auth.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> GoogleLoginAsync(string googleToken);
        Task<AuthResponse> RefreshTokenAsync(string token, string refreshToken);
        Task RevokeTokenAsync(string token);
    }
}
