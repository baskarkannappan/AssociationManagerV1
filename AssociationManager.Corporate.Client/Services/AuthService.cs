using AssociationManager.Shared.DTOs;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Client.Services;

public class AuthService
{
    private readonly HttpClient _httpClient;
    private readonly TokenService _tokenService;
    private readonly CustomAuthenticationStateProvider _authStateProvider;

    public AuthService(HttpClient httpClient, TokenService tokenService, CustomAuthenticationStateProvider authStateProvider)
    {
        _httpClient = httpClient;
        _tokenService = tokenService;
        _authStateProvider = authStateProvider;
    }

    public async Task<AuthResponse?> LoginWithGoogle(string idToken)
    {
        var result = await _httpClient.PostAsJsonAsync("auth/google", new GoogleLoginRequest { IdToken = idToken });
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
        var result = await _httpClient.PostAsJsonAsync("auth/switch-tenant", new SwitchTenantRequest { TenantId = tenantId, AssociationId = associationId });
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
}
