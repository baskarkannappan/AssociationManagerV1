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

        // 1. Try Query String (Most resilient to gateway scrubbing)
        idToken = Request.Query["t"].ToString();
        if (!string.IsNullOrEmpty(idToken)) _logger.LogInformation("[AUTH_B2C] Received ID Token via Query String (Length: {Length}).", idToken.Length);

        // 2. Try Custom Headers
        if (string.IsNullOrEmpty(idToken))
        {
            idToken = Request.Headers["X-Identity-Token"].ToString();
            if (string.IsNullOrEmpty(idToken)) idToken = Request.Headers["X-ID-Token"].ToString();
            if (!string.IsNullOrEmpty(idToken)) _logger.LogInformation("[AUTH_B2C] Received ID Token via Header (Length: {Length}).", idToken.Length);
        }

        // 3. Try Form Data Fallback
        if (string.IsNullOrEmpty(idToken))
        {
            try { idToken = Request.Form["IdToken"].ToString(); } catch { }
            if (!string.IsNullOrEmpty(idToken)) _logger.LogInformation("[AUTH_B2C] Received ID Token via Form Data.");
        }

        if (!string.IsNullOrEmpty(idToken))
        {
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var jwt = handler.ReadJwtToken(idToken);
                var identity = new ClaimsIdentity(jwt.Claims, "B2C");
                principal = new ClaimsPrincipal(identity);
            }
            catch (Exception ex) { _logger.LogWarning(ex, "[AUTH_B2C] Failed to decode manual ID Token."); }
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
            string? fallbackToken = null;
            
            if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                fallbackToken = authHeader.Substring(7);
            }
            
            if (!string.IsNullOrEmpty(fallbackToken))
            {
                try
                {
                    var handler = new JwtSecurityTokenHandler();
                    var jwt = handler.ReadJwtToken(fallbackToken);
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
