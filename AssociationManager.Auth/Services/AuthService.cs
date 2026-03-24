using AssociationManager.Auth.Interfaces;
using AssociationManager.Auth.Models;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.DTOs;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
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
    private readonly IAssociationRepository _associationRepository;
    private readonly IDistributedCache _cache;
    private readonly JwtSettings _jwtSettings;
    private readonly GoogleSettings _googleSettings;

    public AuthService(
        IUserRepository userRepository,
        ITenantRepository tenantRepository,
        IAssociationRepository associationRepository,
        IDistributedCache cache,
        IOptions<JwtSettings> jwtSettings,
        IOptions<GoogleSettings> googleSettings)
    {
        _userRepository = userRepository;
        _tenantRepository = tenantRepository;
        _associationRepository = associationRepository;
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
                // 1. Try local schema (assoc or corp)
                user = await _userRepository.GetByEmailAsync(payload.Email);
                
                if (user == null)
                {
                    // 2. Try global schema (corp) as fallback for Admins
                    var globalUser = await _userRepository.GetByEmailGlobalAsync(payload.Email);
                    if (globalUser != null && (globalUser.Role == AppRole.SystemAdmin || globalUser.Role == AppRole.PlatformAdmin))
                    {
                        // Provision this global admin into the local (assoc) schema
                        globalUser.UserId = 0; // Ensure new ID
                        globalUser.GoogleId = payload.Subject;
                        globalUser.CreatedDate = DateTime.UtcNow;
                        var newId = await _userRepository.CreateAsync(globalUser);
                        user = await _userRepository.GetByIdAsync(newId);
                    }
                }

                if (user == null)
                {
                    return new AuthResponse { Success = false, Message = "Access Denied: Your email is not configured in the system. Please contact your administrator." };
                }

                // Link their newly authenticated GoogleId to their record
                user.GoogleId = payload.Subject;
            }

            user.Name = payload.Name;
            user.PictureUrl = payload.Picture;
            user.LastLoginDate = DateTime.UtcNow;
            
            /* 
            // Auto-select first association if none is assigned but mappings exist
            if (user.AssociationId == null || user.AssociationId == 0)
            {
                var associations = await _associationRepository.GetByUserIdAsync(user.UserId);
                var firstAssoc = associations.FirstOrDefault();
                if (firstAssoc != null)
                {
                    user.AssociationId = firstAssoc.AssociationId;
                    user.TenantId = firstAssoc.TenantId;
                }
            }
            */

            await _userRepository.UpdateAsync(user);

            // Get the role for the current tenant or association
            var roleId = user.AssociationId > 0 ? user.AssociationId.Value : user.TenantId;
            var role = await _userRepository.GetRoleInTenantAsync(user.UserId, roleId);
            
            // Final role resolution
            if (user.AssociationId > 0)
            {
                // In association context, role is determined by mapping, defaulting to Resident
                user.Role = role ?? AppRole.Resident;
            }
            else
            {
                // In corporate/tenant context, keep corporate roles if assigned, or use mapping
                if (AppRole.IsCorporateRole(user.Role))
                {
                    if (!string.IsNullOrEmpty(role) && user.Role != role)
                    {
                        user.Role = $"{user.Role}, {role}";
                    }
                }
                else
                {
                    user.Role = role ?? AppRole.Resident;
                }
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

        var email = principal.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Email)?.Value;
        if (string.IsNullOrEmpty(email)) return new AuthResponse { Success = false, Message = "Invalid email in token" };

        var savedRefreshToken = await _cache.GetStringAsync($"refreshToken:{email}");
        if (savedRefreshToken != refreshToken) return new AuthResponse { Success = false, Message = "Invalid refresh token" };

        var userIdStr = principal.Claims.FirstOrDefault(c => c.Type == "UserId")?.Value;
        if (!int.TryParse(userIdStr, out int userId)) return new AuthResponse { Success = false, Message = "Invalid user in token" };

        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null) return new AuthResponse { Success = false, Message = "User not found" };

        return await GenerateAuthResponse(user);
    }

    private async Task<AuthResponse> GenerateAuthResponse(User user)
    {
        var token = GenerateJwtToken(user);
        var refreshToken = GenerateRefreshToken();

        // Store refresh token in Redis with expiry
        await _cache.SetStringAsync($"refreshToken:{user.Email}", refreshToken, new DistributedCacheEntryOptions
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

        var claims = new List<Claim>
        {
            new Claim("sub", user.Email),
            new Claim("email", user.Email),
            new Claim("jti", Guid.NewGuid().ToString()),
            new Claim("UserId", user.UserId.ToString()),
            new Claim("TenantId", user.TenantId.ToString()),
            new Claim("AssociationId", (user.AssociationId?.ToString() ?? "0")),
            new Claim("name", user.Name),
            new Claim("DeviceId", "Web") // Simplified for now
        };

        if (!string.IsNullOrEmpty(user.Role))
        {
            var roles = user.Role.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            foreach (var r in roles)
            {
                claims.Add(new Claim("role", r));
            }
        }

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

    public async Task<AuthResponse> SwitchTenantAsync(int userId, int tenantId, int associationId)
    {
        var isAuthorized = await _userRepository.IsUserAuthorisedForAssociationAsync(userId, tenantId, associationId);
        if (!isAuthorized)
        {
            return new AuthResponse { Success = false, Message = "User not authorized for this association." };
        }

        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
        {
            return new AuthResponse { Success = false, Message = "User not found." };
        }

        // Update the user's current tenant and association for the session/token
        user.TenantId = tenantId;
        user.AssociationId = associationId;
        
        // Refresh the role for this specific tenant or association
        var roleId = associationId > 0 ? associationId : tenantId;
        var role = await _userRepository.GetRoleInTenantAsync(userId, roleId);
        
        // Final role resolution
        if (associationId > 0)
        {
            // In association context, role is determined by mapping, defaulting to Resident
            user.Role = role ?? AppRole.Resident;
        }
        else
        {
            // In corporate/tenant context, keep corporate roles if assigned, or use mapping
            if (AppRole.IsCorporateRole(user.Role))
            {
                if (!string.IsNullOrEmpty(role) && user.Role != role)
                {
                    user.Role = $"{user.Role}, {role}";
                }
            }
            else
            {
                user.Role = role ?? AppRole.Resident;
            }
        }

        await _userRepository.UpdateAsync(user);

        return await GenerateAuthResponse(user);
    }
}
