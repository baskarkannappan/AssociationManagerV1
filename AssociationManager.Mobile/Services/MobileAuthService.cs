using AssociationManager.Shared.DTOs;
using System.Net.Http.Json;
using System.Net.Http.Headers;

namespace AssociationManager.Mobile.Services;

public class MobileAuthService
{
    private readonly HttpClient _httpClient;
    private readonly MobileTokenStorageService _tokenService;

    public MobileAuthService(IHttpClientFactory httpClientFactory, MobileTokenStorageService tokenService)
    {
        _httpClient = httpClientFactory.CreateClient("AuthClient");
        _tokenService = tokenService;
    }

    public async Task<bool> LoginWithGoogleAsync(string idToken)
    {
        try
        {
            var result = await _httpClient.PostAsJsonAsync("api/auth/google", new GoogleLoginRequest { IdToken = idToken });
            if (result.IsSuccessStatusCode)
            {
                var response = await result.Content.ReadFromJsonAsync<AuthResponse>();
                if (response?.Success == true)
                {
                    await _tokenService.SaveTokenAsync(response.Token!);
                    return true;
                }
            }
        }
        catch (Exception)
        {
            return false;
        }
        return false;
    }

    public async Task<AuthResponse?> SwitchTenantAsync(int tenantId, int associationId)
    {
        var token = await _tokenService.GetTokenAsync();
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
                await _tokenService.SaveTokenAsync(response.Token!);
                await _tokenService.SaveTenantContextAsync(tenantId, associationId, false);
            }
            return response;
        }
        return new AuthResponse { Success = false, Message = "Tenant switch failed" };
    }

    public async Task<AuthResponse?> RefreshToken()
    {
        var token = await _tokenService.GetTokenAsync();
        var refreshToken = "NOT_IMPLEMENTED_IN_MOBILE_STORAGE_YET"; // We should add refresh token storage if backend requires it.
        
        if (string.IsNullOrEmpty(token)) return null;

        var result = await _httpClient.PostAsJsonAsync("api/auth/refresh", new { Token = token, RefreshToken = refreshToken });
        if (result.IsSuccessStatusCode)
        {
            var response = await result.Content.ReadFromJsonAsync<AuthResponse>();
            if (response?.Success == true)
            {
                await _tokenService.SaveTokenAsync(response.Token!);
                return response;
            }
        }
        return null;
    }

    public void Logout()
    {
        _tokenService.ClearAll();
    }
}
