using AssociationManager.Client.Services;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components;

namespace AssociationManager.Client.Services;

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
        // Correlation ID for distributed tracing
        if (!request.Headers.Contains("X-Correlation-ID"))
        {
            request.Headers.Add("X-Correlation-ID", Guid.NewGuid().ToString());
        }

        // Avoid infinite loop: don't refresh if we are already calling the auth endpoints
        var requestPath = request.RequestUri?.ToString() ?? "";
        if (!requestPath.Contains("api/auth/refresh") && !requestPath.Contains("api/auth/google"))
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
