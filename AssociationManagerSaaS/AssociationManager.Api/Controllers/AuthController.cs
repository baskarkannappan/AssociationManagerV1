using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using AssociationManager.Auth.Interfaces;
using AssociationManager.Shared.DTOs;

namespace AssociationManager.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("google-login")]
        public async Task<IActionResult> GoogleLogin([FromBody] string googleToken)
        {
            var response = await _authService.GoogleLoginAsync(googleToken);
            return Ok(response);
        }

        [HttpPost("refresh")]
        public async Task<IActionResult> Refresh([FromBody] AuthResponse request)
        {
            var response = await _authService.RefreshTokenAsync(request.Token, request.RefreshToken);
            return Ok(response);
        }

        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            var token = Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
            await _authService.RevokeTokenAsync(token);
            return Ok();
        }
    }
}
