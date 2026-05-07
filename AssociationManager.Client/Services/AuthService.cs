using AssociationManager.Shared.DTOs;
using System.Net.Http;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class AuthService
{
    private readonly HttpClient _httpClient;
    private readonly TokenService _tokenService;
    private readonly CustomAuthenticationStateProvider _authStateProvider;
    private static readonly SemaphoreSlim _refreshSemaphore = new(1, 1);
    private static Task<AuthResponse?>? _refreshTask;

    public AuthService(IHttpClientFactory httpClientFactory, TokenService tokenService, CustomAuthenticationStateProvider authStateProvider)
    {
        _httpClient = httpClientFactory.CreateClient("AuthClient");
        _tokenService = tokenService;
        _authStateProvider = authStateProvider;
    }

    public async Task<AuthResponse?> LoginWithB2C(string b2cToken)
    {
        // Send the raw CIAM token as a custom header, NOT as Authorization: Bearer.
        // Sending it as Bearer would trigger the JWT middleware to validate it against
        // our API's audience (af161f39), which would fail and return 401 before
        // the controller action even runs — even on [AllowAnonymous] endpoints.
        _httpClient.DefaultRequestHeaders.Remove("X-B2C-Token");
        _httpClient.DefaultRequestHeaders.Add("X-B2C-Token", b2cToken);
        var result = await _httpClient.PostAsync("api/auth/b2c-login", null);
        _httpClient.DefaultRequestHeaders.Remove("X-B2C-Token");
        if (result.IsSuccessStatusCode)
        {
            var response = await result.Content.ReadFromJsonAsync<AuthResponse>();
            if (response?.Success == true)
            {
                await _tokenService.SetTokens(response.Token!, response.RefreshToken!);
                _authStateProvider.NotifyUserAuthentication(response.Token!);
            }
            return response;
        }
        return new AuthResponse { Success = false, Message = "Login failed" };
    }

    public async Task Logout()
    {
        await _tokenService.RemoveTokens();
        _authStateProvider.NotifyUserLogout();
    }

    public async Task<AuthResponse?> SwitchTenant(int tenantId, int associationId)
    {
        var token = await _tokenService.GetToken();
        if (!string.IsNullOrEmpty(token))
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        var result = await _httpClient.PostAsJsonAsync("api/auth/switch-tenant", new SwitchTenantRequest { TenantId = tenantId, AssociationId = associationId });
        if (result.IsSuccessStatusCode)
        {
            var response = await result.Content.ReadFromJsonAsync<AuthResponse>();
            if (response?.Success == true)
            {
                await _tokenService.SetTokens(response.Token!, response.RefreshToken!);
                _authStateProvider.NotifyUserAuthentication(response.Token!);
            }
            return response;
        }
        return new AuthResponse { Success = false, Message = "Tenant switch failed" };
    }

    public async Task<AuthResponse?> RefreshToken()
    {
        await _refreshSemaphore.WaitAsync();
        try
        {
            if (_refreshTask != null) return await _refreshTask;

            _refreshTask = DoRefreshToken();
            var result = await _refreshTask;
            return result;
        }
        finally
        {
            _refreshTask = null;
            _refreshSemaphore.Release();
        }
    }

    private async Task<AuthResponse?> DoRefreshToken()
    {
        var token = await _tokenService.GetToken();
        var refreshToken = await _tokenService.GetRefreshToken();
        
        if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(refreshToken)) return null;

        var result = await _httpClient.PostAsJsonAsync("api/auth/refresh", new { Token = token, RefreshToken = refreshToken });
        if (result.IsSuccessStatusCode)
        {
            var response = await result.Content.ReadFromJsonAsync<AuthResponse>();
            if (response?.Success == true)
            {
                await _tokenService.SetTokens(response.Token!, response.RefreshToken!);
                _authStateProvider.NotifyUserAuthentication(response.Token!);
                return response;
            }
        }
        
        await Logout();
        return null;
    }
}
