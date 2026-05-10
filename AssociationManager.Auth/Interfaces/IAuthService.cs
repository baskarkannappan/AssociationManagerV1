using AssociationManager.Shared.DTOs;
using System.Security.Claims;
using System.Threading.Tasks;

namespace AssociationManager.Auth.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> B2CLoginAsync(ClaimsPrincipal principal);
    Task<AuthResponse> RefreshTokenAsync(string token, string refreshToken);
    Task<AuthResponse> SwitchTenantAsync(int userId, string? email, int tenantId, int associationId);
}
