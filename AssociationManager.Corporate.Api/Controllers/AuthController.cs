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
    public async Task<IActionResult> B2CLogin()
    {
        ClaimsPrincipal? principal = null;
        string? idToken = null;

        _logger.LogInformation("[AUTH_B2C] Starting Identity Scan. Path: {Path}", Request.Path);

        // SECURITY HARDENING: Limit scan count to prevent DoS via header/query bloat
        int scanCount = 0;
        const int SCAN_LIMIT = 50;

        // 1. Scan ALL Headers for a JWT (Priority: Safer than URL)
        foreach (var header in Request.Headers)
        {
            if (++scanCount > SCAN_LIMIT) break;
            if (header.Key.Equals("Authorization", StringComparison.OrdinalIgnoreCase)) continue;
            var val = header.Value.ToString();
            if (val.StartsWith("eyJ", StringComparison.OrdinalIgnoreCase))
            {
                idToken = val;
                _logger.LogInformation("[AUTH_B2C] Resolved JWT from secure Header '{Key}'.", header.Key);
                break;
            }
        }

        // 2. Scan Query Parameters (Fallback only - Warning logged for production review)
        if (string.IsNullOrEmpty(idToken))
        {
            foreach (var query in Request.Query)
            {
                if (++scanCount > SCAN_LIMIT) break;
                var val = query.Value.ToString();
                if (val.StartsWith("eyJ", StringComparison.OrdinalIgnoreCase))
                {
                    idToken = val;
                    _logger.LogWarning("[AUTH_B2C] WARNING: JWT resolved from URL Query. This is deprecated for Production security.");
                    break;
                }
            }
        }

        // 3. Decode the found token
        if (!string.IsNullOrEmpty(idToken))
        {
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var jwt = handler.ReadJwtToken(idToken);
                var identity = new ClaimsIdentity(jwt.Claims, "B2C");
                principal = new ClaimsPrincipal(identity);
            }
            catch (Exception ex) { _logger.LogWarning(ex, "[AUTH_B2C] Failed to decode found JWT."); }
        }

        // 4. Fallback to middleware principal (if JWT was valid but identity was handled by middleware)
        if (principal == null)
        {
            principal = User.Identity?.IsAuthenticated == true ? User : null;
            if (principal != null) _logger.LogInformation("[AUTH_B2C] Using principal from middleware fallback.");
        }

        if (principal == null)
        {
            _logger.LogWarning("[AUTH_B2C] Hyper-Scan failed. No JWT found in Query or Headers. Headers Present: {Headers}", string.Join(", ", Request.Headers.Keys));
            return Unauthorized(new AuthResponse { Success = false, Message = "Identity token not found. Please ensure you are sending the ID Token." });
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
