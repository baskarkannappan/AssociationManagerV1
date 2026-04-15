using AssociationManager.Corporate.Client.Services;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components;

namespace AssociationManager.Corporate.Client.Services;

public class AuthHeaderHandler : DelegatingHandler
{
    private readonly TokenService _tokenService;
    private readonly AuthService _authService;
    private readonly NavigationManager _navigationManager;

    public AuthHeaderHandler(TokenService tokenService, AuthService authService, NavigationManager navigationManager)
    {
        _tokenService = tokenService;
        _authService = authService;
        _navigationManager = navigationManager;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        // Avoid infinite loop: don't refresh if we are already calling the auth endpoints
        var requestPath = request.RequestUri?.ToString() ?? "";
        if (!requestPath.Contains("api/corporate/auth/refresh") && !requestPath.Contains("api/corporate/auth/google"))
        {
            if (await _tokenService.IsTokenExpired())
            {
                System.Console.WriteLine("[AuthHeaderHandler] Token expired, attempting refresh...");
                var refreshResult = await _authService.RefreshToken();
                if (refreshResult == null || !refreshResult.Success)
                {
                    System.Console.WriteLine("[AuthHeaderHandler] Refresh failed, redirecting to login...");
                    _navigationManager.NavigateTo("/login");
                    return new HttpResponseMessage(System.Net.HttpStatusCode.Unauthorized);
                }
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
