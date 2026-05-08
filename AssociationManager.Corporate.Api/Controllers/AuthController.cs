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

namespace AssociationManager.Corporate.Api.Controllers;

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

    public class B2CLoginRequest
    {
        public string? AccessToken { get; set; }
        public string? IdToken { get; set; }
    }

    [HttpPost("b2c-login")]
    [AllowAnonymous]
    public async Task<IActionResult> B2CLogin([FromBody] B2CLoginRequest? request)
    {
        ClaimsPrincipal? principal = null;
        string? rawToken = null;

        // 1. Check for the ID Token in the request body (Most reliable for CIAM identity)
        if (!string.IsNullOrEmpty(request?.IdToken))
        {
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var jwt = handler.ReadJwtToken(request.IdToken);
                var identity = new ClaimsIdentity(jwt.Claims, "B2C");
                principal = new ClaimsPrincipal(identity);
                _logger.LogInformation("[AUTH_B2C] Using ID Token from Request Body for identity claims.");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "[AUTH_B2C] Failed to decode ID Token from body.");
            }
        }

        // 2. Fallback to ID Token from custom header (Old method)
        if (principal == null)
        {
            var idTokenHeader = Request.Headers["X-ID-Token"].ToString();
            if (!string.IsNullOrEmpty(idTokenHeader))
            {
                try
                {
                    var handler = new JwtSecurityTokenHandler();
                    var jwt = handler.ReadJwtToken(idTokenHeader);
                    var identity = new ClaimsIdentity(jwt.Claims, "B2C");
                    principal = new ClaimsPrincipal(identity);
                    _logger.LogInformation("[AUTH_B2C] Using ID Token from X-ID-Token header.");
                }
                catch (Exception ex) { _logger.LogWarning(ex, "[AUTH_B2C] Failed to decode X-ID-Token header."); }
            }
        }

        // 3. If still no identity, try to get the principal from the already authenticated user (if middleware succeeded)
        if (principal == null)
        {
            principal = User.Identity?.IsAuthenticated == true ? User : null;
            if (principal != null) _logger.LogInformation("[AUTH_B2C] Using principal from middleware (Access Token).");
        }

        // 4. Final Fallback: Manual extraction from Authorization header
        if (principal == null)
        {
            var authHeader = Request.Headers["Authorization"].ToString();
            if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                rawToken = authHeader.Substring(7);
            }
            
            if (string.IsNullOrEmpty(rawToken))
            {
                rawToken = request?.AccessToken;
            }

            if (!string.IsNullOrEmpty(rawToken))
            {
                try
                {
                    var handler = new JwtSecurityTokenHandler();
                    var jwt = handler.ReadJwtToken(rawToken);
                    var identity = new ClaimsIdentity(jwt.Claims, "B2C");
                    principal = new ClaimsPrincipal(identity);
                    _logger.LogInformation("[AUTH_B2C] Using manually extracted Access Token for identity.");
                }
                catch (Exception ex) { _logger.LogWarning(ex, "[AUTH_B2C] Failed to decode manual Access Token."); }
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
        _logger.LogWarning("B2C Login failed: {Message}", response.Message);
        return Unauthorized(response);
    }

    [HttpPost("refresh")]
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
