using AssociationManager.Shared.DTOs;
using System.Net.Http;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Client.Services;

public class AuthService
{
    private readonly HttpClient _httpClient;
    private readonly TokenService _tokenService;
    private readonly CustomAuthenticationStateProvider _authStateProvider;

    public AuthService(IHttpClientFactory httpClientFactory, TokenService tokenService, CustomAuthenticationStateProvider authStateProvider)
    {
        _httpClient = httpClientFactory.CreateClient("AuthClient");
        _tokenService = tokenService;
        _authStateProvider = authStateProvider;
    }

    public async Task<AuthResponse?> LoginWithB2C(string accessToken, string? idToken = null)
    {
        // Use standard Authorization: Bearer header for the Access Token (for middleware validation).
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        
        // Use custom X-ID-Token header for the ID Token (for identity claims mapping).
        if (!string.IsNullOrEmpty(idToken))
        {
            _httpClient.DefaultRequestHeaders.Add("X-ID-Token", idToken);
        }
        
        var result = await _httpClient.PostAsync("auth/b2c-login", null);
        
        // Clear headers immediately after
        _httpClient.DefaultRequestHeaders.Authorization = null;
        _httpClient.DefaultRequestHeaders.Remove("X-ID-Token");

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

        var result = await _httpClient.PostAsJsonAsync("api/corporate/auth/switch-tenant", new SwitchTenantRequest { TenantId = tenantId, AssociationId = associationId });
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
        var token = await _tokenService.GetToken();
        var refreshToken = await _tokenService.GetRefreshToken();
        
        if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(refreshToken)) return null;

        var result = await _httpClient.PostAsJsonAsync("api/corporate/auth/refresh", new { Token = token, RefreshToken = refreshToken });
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
