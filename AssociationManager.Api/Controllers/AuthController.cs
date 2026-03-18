using AssociationManager.Auth.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ITenantContext _tenantContext;

    public AuthController(IAuthService authService, ITenantContext tenantContext)
    {
        _authService = authService;
        _tenantContext = tenantContext;
    }

    [HttpPost("google")]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)
    {
        var response = await _authService.GoogleLoginAsync(request.IdToken);
        if (response.Success)
        {
            return Ok(response);
        }
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
        if (userId == 0) return Unauthorized();

        var response = await _authService.SwitchTenantAsync(userId, request.TenantId, request.AssociationId);
        if (response.Success)
        {
            return Ok(response);
        }
        return BadRequest(response);
    }
}
