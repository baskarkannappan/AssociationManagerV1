using System.Collections.Generic;
using System.Security.Claims;
using AssociationManager.Shared.Models;

namespace AssociationManager.Auth.Interfaces
{
    public interface ITokenService
    {
        string GenerateAccessToken(User user, int? tenantId, IEnumerable<string> roles);
        string GenerateRefreshToken();
        ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
    }
}
