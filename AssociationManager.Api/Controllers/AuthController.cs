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
        // Manually decode the CIAM token from the Authorization header.
        // We cannot rely on the middleware-populated User because CIAM issuer
        // validation may fail, leaving ClaimsPrincipal empty.
        var authHeader = Request.Headers["Authorization"].ToString();
        if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning("[AUTH_B2C] No Bearer token found in Authorization header.");
            return Unauthorized(new AuthResponse { Success = false, Message = "Missing authorization token." });
        }

        var rawToken = authHeader.Substring("Bearer ".Length).Trim();
        ClaimsPrincipal principal;
        try
        {
            var handler = new JwtSecurityTokenHandler();
            var jwt = handler.ReadJwtToken(rawToken);
            var identity = new ClaimsIdentity(jwt.Claims, "B2C");
            principal = new ClaimsPrincipal(identity);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "[AUTH_B2C] Failed to decode bearer token.");
            return Unauthorized(new AuthResponse { Success = false, Message = "Invalid token format." });
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
