using AssociationManager.Auth.Interfaces;
using AssociationManager.Auth.Models;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.DTOs;
using AssociationManager.Shared.Models;
using Google.Apis.Auth;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace AssociationManager.Auth.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly IDistributedCache _cache;
    private readonly JwtSettings _jwtSettings;
    private readonly GoogleSettings _googleSettings;

    public AuthService(
        IUserRepository userRepository,
        ITenantRepository tenantRepository,
        IDistributedCache cache,
        IOptions<JwtSettings> jwtSettings,
        IOptions<GoogleSettings> googleSettings)
    {
        _userRepository = userRepository;
        _tenantRepository = tenantRepository;
        _cache = cache;
        _jwtSettings = jwtSettings.Value;
        _googleSettings = googleSettings.Value;
    }

    public async Task<AuthResponse> GoogleLoginAsync(string idToken)
    {
        try
        {
            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = new[] { _googleSettings.ClientId }
            });

            var user = await _userRepository.GetByGoogleIdAsync(payload.Subject);
            if (user == null)
            {
                // For demo/simplicity, ensure a default tenant exists or create one
                var tenants = await _tenantRepository.GetAllAsync();
                var defaultTenant = tenants.FirstOrDefault() ?? new Tenant { Name = "Default Organization" };
                if (defaultTenant.TenantId == 0)
                {
                    defaultTenant.TenantId = await _tenantRepository.CreateAsync(defaultTenant);
                }

                user = new User
                {
                    GoogleId = payload.Subject,
                    Email = payload.Email,
                    Name = payload.Name,
                    PictureUrl = payload.Picture,
                    TenantId = defaultTenant.TenantId,
                    CreatedDate = DateTime.UtcNow,
                    LastLoginDate = DateTime.UtcNow,
                    IsActive = true,
                    Role = "User"
                };
                user.UserId = await _userRepository.CreateAsync(user);

                // Add entry to UserAssociations for the initial tenant
                await _userRepository.AddUserToTenantAsync(user.UserId, user.TenantId, user.Role);
            }
            user.PictureUrl = payload.Picture;
            await _userRepository.UpdateAsync(user);

            // Ensure the role is correct for the current tenant
            var role = await _userRepository.GetRoleInTenantAsync(user.UserId, user.TenantId);
            if (!string.IsNullOrEmpty(role))
            {
                user.Role = role;
            }

            return await GenerateAuthResponse(user);
        }
        catch (Exception ex)
        {
            return new AuthResponse { Success = false, Message = $"Authentication failed: {ex.Message}" };
        }
    }

    public async Task<AuthResponse> RefreshTokenAsync(string token, string refreshToken)
    {
        var principal = GetPrincipalFromExpiredToken(token);
        if (principal == null) return new AuthResponse { Success = false, Message = "Invalid access token" };

        var userIdStr = principal.Claims.FirstOrDefault(c => c.Type == "UserId")?.Value;
        if (!int.TryParse(userIdStr, out int userId)) return new AuthResponse { Success = false, Message = "Invalid user in token" };

        var savedRefreshToken = await _cache.GetStringAsync($"refreshToken:{userId}");
        if (savedRefreshToken != refreshToken) return new AuthResponse { Success = false, Message = "Invalid refresh token" };

        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null) return new AuthResponse { Success = false, Message = "User not found" };

        return await GenerateAuthResponse(user);
    }

    private async Task<AuthResponse> GenerateAuthResponse(User user)
    {
        var token = GenerateJwtToken(user);
        var refreshToken = GenerateRefreshToken();

        // Store refresh token in Redis with expiry
        await _cache.SetStringAsync($"refreshToken:{user.UserId}", refreshToken, new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromDays(_jwtSettings.RefreshExpiryInDays)
        });

        return new AuthResponse
        {
            Success = true,
            Token = token,
            RefreshToken = refreshToken,
            Email = user.Email,
            Name = user.Name
        };
    }

    private string GenerateJwtToken(User user)
    {
        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Key));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Email),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("UserId", user.UserId.ToString()),
            new Claim("TenantId", user.TenantId.ToString()),
            new Claim("Role", user.Role),
            new Claim("Name", user.Name),
            new Claim("DeviceId", "Web") // Simplified for now
        };

        var token = new JwtSecurityToken(
            issuer: _jwtSettings.Issuer,
            audience: _jwtSettings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_jwtSettings.ExpiryInMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    private ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = false,
            ValidateIssuer = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Key)),
            ValidateLifetime = false
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out SecurityToken securityToken);
        if (securityToken is not JwtSecurityToken jwtSecurityToken || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            return null;


        return principal;
    }

    public async Task<AuthResponse> SwitchTenantAsync(int userId, int tenantId)
    {
        var isAuthorized = await _userRepository.IsUserInTenantAsync(userId, tenantId);
        if (!isAuthorized)
        {
            return new AuthResponse { Success = false, Message = "User does not belong to the requested tenant." };
        }

        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
        {
            return new AuthResponse { Success = false, Message = "User not found." };
        }

        // Update the user's current tenant for the session/token
        user.TenantId = tenantId;
        
        // Refresh the role for this specific tenant
        var role = await _userRepository.GetRoleInTenantAsync(userId, tenantId);
        if (!string.IsNullOrEmpty(role))
        {
            user.Role = role;
        }

        return await GenerateAuthResponse(user);
    }
}
