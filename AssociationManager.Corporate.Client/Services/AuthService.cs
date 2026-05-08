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

    public class B2CLoginRequest
    {
        public string? AccessToken { get; set; }
        public string? IdToken { get; set; }
    }

    public async Task<AuthResponse?> LoginWithB2C(string accessToken, string? idToken = null)
    {
        // Still set the Bearer header for middleware validation
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        
        var request = new B2CLoginRequest
        {
            AccessToken = accessToken,
            IdToken = idToken
        };
        
        var result = await _httpClient.PostAsJsonAsync("auth/b2c-login", request);
        
        // Clear headers immediately after
        _httpClient.DefaultRequestHeaders.Authorization = null;

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
