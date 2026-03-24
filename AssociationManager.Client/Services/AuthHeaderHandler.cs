using AssociationManager.Client.Services;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class AuthHeaderHandler : DelegatingHandler
{
    private readonly TokenService _tokenService;
    private readonly AuthService _authService;

    public AuthHeaderHandler(TokenService tokenService, AuthService authService)
    {
        _tokenService = tokenService;
        _authService = authService;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        // Avoid infinite loop: don't refresh if we are already calling the auth endpoints
        var requestPath = request.RequestUri?.ToString() ?? "";
        if (!requestPath.Contains("api/auth/refresh") && !requestPath.Contains("api/auth/google"))
        {
            if (await _tokenService.IsTokenExpired())
            {
                System.Console.WriteLine("[AuthHeaderHandler] Token expired, attempting refresh...");
                await _authService.RefreshToken();
            }
        }

        var token = await _tokenService.GetToken();
        if (!string.IsNullOrEmpty(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        return await base.SendAsync(request, cancellationToken);
    }
}
