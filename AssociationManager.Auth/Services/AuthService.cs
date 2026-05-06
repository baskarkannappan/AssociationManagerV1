using AssociationManager.Auth.Interfaces;
using AssociationManager.Auth.Models;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.DTOs;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using Google.Apis.Auth;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;
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
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IUserRepository userRepository,
        ITenantRepository tenantRepository,
        IAssociationRepository associationRepository,
        IDistributedCache cache,
        IOptions<JwtSettings> jwtSettings,
        ILogger<AuthService> logger)
    {
        _userRepository = userRepository;
        _tenantRepository = tenantRepository;
        _associationRepository = associationRepository;
        _cache = cache;
        _jwtSettings = jwtSettings.Value;
        _logger = logger;
    }

    public async Task<AuthResponse> B2CLoginAsync(ClaimsPrincipal principal)
    {
        var subjectId = principal.Claims.FirstOrDefault(c => c.Type == "sub" || c.Type == ClaimTypes.NameIdentifier)?.Value;
        var email = principal.Claims.FirstOrDefault(c => c.Type == "emails" || c.Type == "email" || c.Type == ClaimTypes.Email)?.Value;
        var name = principal.Claims.FirstOrDefault(c => c.Type == "name" || c.Type == ClaimTypes.Name)?.Value ?? "B2C User";
        var picture = principal.Claims.FirstOrDefault(c => c.Type == "picture")?.Value;

        if (string.IsNullOrEmpty(subjectId) || string.IsNullOrEmpty(email))
        {
            _logger.LogWarning("[AUTH_B2C] Missing critical claims. Sub: {Sub}, Email: {Email}", subjectId, email);
            return new AuthResponse { Success = false, Message = "Invalid authentication token: Missing Subject or Email claims." };
        }

        _logger.LogInformation("[AUTH_B2C] Processing login for {Email} (Subject: {Subject})", email, subjectId);

        try
        {
            // 1. Try lookup by SubjectId (Primary B2C Identifier)
            var user = await _userRepository.GetBySubjectIdAsync(subjectId);
            
            if (user == null)
            {
                // 2. MIGRATION BRIDGE: Try lookup by Email
                user = await _userRepository.GetByEmailAsync(email);
                
                if (user == null)
                {
                    // 3. Fallback for Admins in global schema
                    var globalUser = await _userRepository.GetByEmailGlobalAsync(email);
                    if (globalUser != null && (globalUser.Role == AppRole.SystemAdmin || 
                                               globalUser.Role == AppRole.PlatformAdmin ||
                                               globalUser.Role == AppRole.AssociationAdmin))
                    {
                        globalUser.UserId = 0;
                        globalUser.SubjectId = subjectId;
                        globalUser.CreatedDate = DateTime.UtcNow;
                        var newId = await _userRepository.CreateAsync(globalUser);
                        user = await _userRepository.GetByIdAsync(newId);
                    }
                }

                if (user != null)
                {
                    // Link the SubjectId for future logins
                    user.SubjectId = subjectId;
                }
            }

            if (user == null)
            {
                return new AuthResponse { Success = false, Message = "Access Denied: Your account is not configured in Association Manager." };
            }

            // Sync profile data from B2C
            user.Name = name;
            if (!string.IsNullOrEmpty(picture)) user.PictureUrl = picture;
            user.LastLoginDate = DateTime.UtcNow;

            // Cleanup roles if needed
            if (!string.IsNullOrEmpty(user.Role) && user.Role.Contains(","))
            {
                user.Role = AppRole.GetRoleHierarchy(user.Role).FirstOrDefault() ?? AppRole.Resident;
            }
            
            // Association resolution logic
            if (user.AssociationId == null || user.AssociationId <= 1)
            {
                var associations = await _associationRepository.GetByUserIdAsync(user.UserId);
                var firstAssoc = associations.FirstOrDefault();
                if (firstAssoc != null)
                {
                    user.AssociationId = firstAssoc.AssociationId;
                    user.TenantId = firstAssoc.TenantId;
                }
            }

            await _userRepository.UpdateAsync(user);

            var roleId = user.AssociationId > 0 ? user.AssociationId.Value : user.TenantId;
            var role = await _userRepository.GetRoleInTenantAsync(user.UserId, roleId);
            user.Role = role ?? user.Role ?? AppRole.Resident;

            var status = "Active";
            if (user.AssociationId > 0)
            {
                var assoc = await _associationRepository.GetByIdAsync(user.AssociationId.Value, user.TenantId);
                status = assoc?.Status ?? "Active";
            }

            return await GenerateAuthResponse(user, user.Role, status);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[AUTH_B2C] Failed to process login for {Email}", email);
            return new AuthResponse { Success = false, Message = $"Authentication processing failed: {ex.Message}" };
        }
    }


    public async Task<AuthResponse> RefreshTokenAsync(string token, string refreshToken)
    {
        _logger.LogInformation("Attempting token refresh...");
        
        ClaimsPrincipal? principal;
        try
        {
            principal = GetPrincipalFromExpiredToken(token);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get principal from expired token.");
            return new AuthResponse { Success = false, Message = "Invalid access token signature or format" };
        }

        if (principal == null) 
        {
            _logger.LogWarning("Principal from expired token is null.");
            return new AuthResponse { Success = false, Message = "Invalid access token" };
        }

        var email = principal.Claims.FirstOrDefault(c => c.Type == "email" || c.Type == ClaimTypes.Email || c.Type == JwtRegisteredClaimNames.Email)?.Value;
        if (string.IsNullOrEmpty(email)) 
        {
            _logger.LogWarning("Email claim missing from token.");
            return new AuthResponse { Success = false, Message = "Invalid email in token" };
        }

        _logger.LogInformation("Refreshing token for {Email}", email);

        var normalizedEmail = email.Trim().ToLowerInvariant();
        var cacheKey = $"refreshToken:{normalizedEmail}";
        var savedRefreshToken = await _cache.GetStringAsync(cacheKey);
        
        if (string.IsNullOrEmpty(savedRefreshToken))
        {
            _logger.LogWarning("No refresh token found in cache for {Email} (Key: {CacheKey})", email, cacheKey);
            return new AuthResponse { Success = false, Message = "Session expired. Please login again." };
        }

        if (savedRefreshToken != refreshToken) 
        {
            _logger.LogWarning("Refresh token mismatch for {Email}. Expected {Saved}, received {Received}", email, savedRefreshToken, refreshToken);
            return new AuthResponse { Success = false, Message = "Invalid refresh token" };
        }

        var userIdStr = principal.Claims.FirstOrDefault(c => c.Type == "UserId")?.Value;
        if (!int.TryParse(userIdStr, out int userId)) 
        {
            _logger.LogWarning("UserId claim missing or invalid for {Email}", email);
            return new AuthResponse { Success = false, Message = "Invalid user in token" };
        }

        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null) 
        {
            _logger.LogWarning("User with ID {UserId} not found during refresh for {Email}", userId, email);
            return new AuthResponse { Success = false, Message = "User not found" };
        }

        _logger.LogInformation("Token refresh successful for {Email}", email);
        
        var contextRole = principal.Claims.FirstOrDefault(c => c.Type == "ContextRole")?.Value;
        var status = principal.Claims.FirstOrDefault(c => c.Type == "AssociationStatus")?.Value ?? "Active";
        var tokenAssociationIdStr = principal.Claims.FirstOrDefault(c => c.Type == "AssociationId")?.Value;
        var tokenTenantIdStr = principal.Claims.FirstOrDefault(c => c.Type == "TenantId")?.Value;

        // Apply context from token to the user object if they are currently viewing a specific association
        // that differs from their DB default (e.g. they switched recently)
        if (int.TryParse(tokenAssociationIdStr, out int tokenAssocId) && tokenAssocId > 0)
        {
            user.AssociationId = tokenAssocId;
        }
        if (int.TryParse(tokenTenantIdStr, out int tokenTenantId) && tokenTenantId > 0)
        {
            user.TenantId = tokenTenantId;
        }

        return await GenerateAuthResponse(user, contextRole, status);
    }

    private async Task<AuthResponse> GenerateAuthResponse(User user, string? contextRole = null, string status = "Active")
    {
        var token = GenerateJwtToken(user, contextRole, status);
        var refreshToken = GenerateRefreshToken();

        // Store refresh token in Redis with expiry
        var cacheKey = $"refreshToken:{user.Email.Trim().ToLowerInvariant()}";
        await _cache.SetStringAsync(cacheKey, refreshToken, new DistributedCacheEntryOptions
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

    private string GenerateJwtToken(User user, string? contextRole = null, string status = "Active")
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
            new Claim("AssociationStatus", status),
            new Claim("name", user.Name),
            new Claim("DeviceId", "Web") // Simplified for now
        };

        if (!string.IsNullOrEmpty(contextRole))
        {
            claims.Add(new Claim("ContextRole", contextRole));
        }

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

    public async Task<AuthResponse> SwitchTenantAsync(int userId, string? email, int tenantId, int associationId)
    {
        // 1. Resolve the correct User record for the CURRENT repository schema (assoc or corp)
        // This handles cases where a token from one API is used in another with a different UserId mapping
        User? user = null;
        if (userId > 0)
        {
            user = await _userRepository.GetByIdAsync(userId);
        }

        // If ID didn't match or was missing, fallback to Email lookup (reliable bridge between schemas)
        if (user == null || (email != null && !user.Email.Equals(email, StringComparison.OrdinalIgnoreCase)))
        {
            if (string.IsNullOrEmpty(email))
            {
                return new AuthResponse { Success = false, Message = "User identity could not be verified." };
            }
            user = await _userRepository.GetByEmailAsync(email);
        }

        if (user == null)
        {
            return new AuthResponse { Success = false, Message = "User not found in this context." };
        }

        // 2. Perform authorization check using the resolved context-specific UserId
        var isAuthorized = await _userRepository.IsUserAuthorisedForAssociationAsync(user.UserId, tenantId, associationId);
        if (!isAuthorized)
        {
            return new AuthResponse { Success = false, Message = "User not authorized for this association." };
        }

        // Update the user's current tenant and association for the session/token
        user.TenantId = tenantId;
        user.AssociationId = associationId;
        
        // Refresh the role for this specific tenant or association
        var roleId = (_userRepository.Schema == "assoc" && associationId > 0) ? associationId : tenantId;
        var newRole = await _userRepository.GetRoleInTenantAsync(user.UserId, roleId);
        
        // Mapping roles are in UserAssociations.
        
        var originalGlobalRole = user.Role;
        if (!string.IsNullOrEmpty(originalGlobalRole) && originalGlobalRole.Contains(","))
        {
            originalGlobalRole = AppRole.GetRoleHierarchy(originalGlobalRole).FirstOrDefault() ?? AppRole.Resident;
        }
        user.Role = MergeRoles(originalGlobalRole, newRole ?? AppRole.Resident);

        // Get current association status
        var assoc = await _associationRepository.GetByIdAsync(associationId, tenantId);
        var status = assoc?.Status ?? "Active";

        // Generate response with merged roles
        var response = await GenerateAuthResponse(user, newRole, status);

        // Restore original role for database update (persist context but not role merge)
        user.Role = originalGlobalRole;
        await _userRepository.UpdateAsync(user);

        return response;
    }

    private string MergeRoles(string? currentRoles, string newRole)
    {
        if (string.IsNullOrEmpty(currentRoles)) return newRole;

        var roles = currentRoles.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToList();
        
        // If the new role is already present, just return current
        if (roles.Contains(newRole, StringComparer.OrdinalIgnoreCase)) return currentRoles;

        // Hierarchy logic: If the user is a high-level admin, keep that role primary
        var highLevelRoles = new[] { AppRole.SystemAdmin, AppRole.PlatformAdmin, AppRole.GlobalUserManager, AppRole.AssociationAdmin };
        bool hasHighLevel = roles.Any(r => highLevelRoles.Contains(r, StringComparer.OrdinalIgnoreCase));

        if (hasHighLevel)
        {
            // Keep high-level roles but add the context role if it's not already there
            if (!roles.Contains(newRole, StringComparer.OrdinalIgnoreCase))
            {
                roles.Add(newRole);
            }
            return string.Join(", ", roles.Distinct());
        }

        // If switching between associations, replace the previous association role but keep global ones
        // For simplicity in this V1, we just return the new role if no high-level global role is present,
        // OR we could keep all non-association roles.
        var associationRoles = AppRole.AssociationRolesArray;
        var cleanedRoles = roles.Where(r => !associationRoles.Contains(r)).ToList();
        cleanedRoles.Add(newRole);

        return string.Join(", ", cleanedRoles.Distinct());
    }
}
