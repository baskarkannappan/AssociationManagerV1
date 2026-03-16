using AssociationManager.Shared.DTOs;
using System.Threading.Tasks;

namespace AssociationManager.Auth.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> GoogleLoginAsync(string idToken);
    Task<AuthResponse> RefreshTokenAsync(string token, string refreshToken);
}
