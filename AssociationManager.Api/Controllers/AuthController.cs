using AssociationManager.Auth.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[AllowAnonymous]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ITenantContext _tenantContext;
    private readonly ILogger<AuthController> _logger;
 
    public AuthController(IAuthService authService, ITenantContext tenantContext, ILogger<AuthController> logger)
    {
        _authService = authService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    [HttpPost("b2c-login")]
    [AllowAnonymous]
    public async Task<IActionResult> B2CLogin()
    {
        // 1. Try to get the principal from the already authenticated user (if middleware succeeded)
        ClaimsPrincipal? principal = User.Identity?.IsAuthenticated == true ? User : null;
        string? rawToken = null;

        // 2. If not authenticated by middleware, try manual extraction from headers
        if (principal == null)
        {
            // Check standard Authorization header first
            var authHeader = Request.Headers["Authorization"].ToString();
            if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                rawToken = authHeader.Substring(7);
            }
            
            // Fallback to custom header for backward compatibility
            if (string.IsNullOrEmpty(rawToken))
            {
                rawToken = Request.Headers["X-B2C-Token"].ToString();
            }

            if (!string.IsNullOrEmpty(rawToken))
            {
                try
                {
                    var handler = new JwtSecurityTokenHandler();
                    var jwt = handler.ReadJwtToken(rawToken);
                    var identity = new ClaimsIdentity(jwt.Claims, "B2C");
                    principal = new ClaimsPrincipal(identity);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "[AUTH_B2C] Failed to decode manual token.");
                }
            }
        }

        if (principal == null)
        {
            _logger.LogWarning("[AUTH_B2C] No valid authentication token found in headers.");
            return Unauthorized(new AuthResponse { Success = false, Message = "Missing or invalid authorization token." });
        }

        var response = await _authService.B2CLoginAsync(principal);
        if (response.Success)
        {
            return Ok(response);
        }
        _logger.LogWarning("B2C Login processing failed: {Message}", response.Message);
        return Unauthorized(response);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        var response = await _authService.RefreshTokenAsync(request.Token, request.RefreshToken);
        if (response.Success)
        {
            return Ok(response);
        }
        return Unauthorized(response);
    }

    [HttpPost("switch-tenant")]
    [Authorize]
    public async Task<IActionResult> SwitchTenant([FromBody] SwitchTenantRequest request)
    {
        var userId = _tenantContext.UserId;
        var email = _tenantContext.Email;
        if (userId == 0 && string.IsNullOrEmpty(email)) return Unauthorized();

        var response = await _authService.SwitchTenantAsync(userId, email, request.TenantId, request.AssociationId);
        if (response.Success)
        {
            return Ok(response);
        }
        return BadRequest(response);
    }
}
