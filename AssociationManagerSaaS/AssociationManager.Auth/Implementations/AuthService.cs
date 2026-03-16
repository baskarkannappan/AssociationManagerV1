using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using AssociationManager.Auth.Interfaces;
using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.DTOs;
using AssociationManager.Shared.Models;

namespace AssociationManager.Auth.Implementations
{
    public class AuthService : IAuthService
    {
        private readonly IUserService _userService;
        private readonly ITenantService _tenantService;
        private readonly ITokenService _tokenService;
        private readonly IRefreshTokenRepository _tokenRepo;

        public AuthService(
            IUserService userService, 
            ITenantService tenantService, 
            ITokenService tokenService, 
            IRefreshTokenRepository tokenRepo)
        {
            _userService = userService;
            _tenantService = tenantService;
            _tokenService = tokenService;
            _tokenRepo = tokenRepo;
        }

        public async Task<AuthResponse> GoogleLoginAsync(string googleToken)
        {
            // Placeholder for Google token verification
            // In a real app, use GoogleJsonWebSignature.ValidateAsync(googleToken)
            string email = "test@example.com";
            string name = "Test User";
            string googleId = "12345";

            var user = await _userService.CreateOrUpdateGoogleUserAsync(email, name, googleId);
            var tenants = await _tenantService.GetUserTenantsAsync(user.Id);
            
            var tenantList = tenants.Select(t => new TenantDto { Id = t.Id, Name = t.Name, Identifier = t.Identifier }).ToList();
            int? currentTenantId = tenantList.FirstOrDefault()?.Id;

            var accessToken = _tokenService.GenerateAccessToken(user, currentTenantId, new List<string> { "User" });
            var refreshToken = _tokenService.GenerateRefreshToken();

            await _tokenRepo.CreateAsync(new RefreshToken
            {
                UserId = user.Id,
                Token = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            });

            return new AuthResponse
            {
                Token = accessToken,
                RefreshToken = refreshToken,
                Email = user.Email,
                FullName = user.FullName,
                Tenants = tenantList,
                CurrentTenantId = currentTenantId
            };
        }

        public async Task<AuthResponse> RefreshTokenAsync(string token, string refreshToken)
        {
            var principal = _tokenService.GetPrincipalFromExpiredToken(token);
            if (principal == null) throw new UnauthorizedAccessException("Invalid token");

            var userId = int.Parse(principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
            var savedRefreshToken = await _tokenRepo.GetByTokenAsync(refreshToken);

            if (savedRefreshToken == null || savedRefreshToken.UserId != userId || !savedRefreshToken.IsActive)
                throw new UnauthorizedAccessException("Invalid refresh token");

            var user = await _userService.GetByEmailAsync(principal.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value ?? "");
            if (user == null) throw new UnauthorizedAccessException("User not found");

            var newAccessToken = _tokenService.GenerateAccessToken(user, null, new List<string> { "User" });
            var newRefreshToken = _tokenService.GenerateRefreshToken();

            savedRefreshToken.IsRevoked = true;
            savedRefreshToken.ReplacedByToken = newRefreshToken;
            await _tokenRepo.UpdateAsync(savedRefreshToken);

            await _tokenRepo.CreateAsync(new RefreshToken
            {
                UserId = user.Id,
                Token = newRefreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            });

            return new AuthResponse
            {
                Token = newAccessToken,
                RefreshToken = newRefreshToken,
                Email = user.Email,
                FullName = user.FullName
            };
        }

        public async Task RevokeTokenAsync(string token)
        {
             var principal = _tokenService.GetPrincipalFromExpiredToken(token);
             if (principal != null)
             {
                 var userId = int.Parse(principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
                 await _tokenRepo.RevokeAllForUserAsync(userId);
             }
        }
    }
}
