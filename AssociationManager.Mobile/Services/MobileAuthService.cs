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

    public async Task<string?> GetTokenFromStorageAsync()
    {
        return await _tokenService.GetTokenAsync();
    }

    public async Task<bool> LoginWithB2CAsync(string b2cToken)
    {
        try
        {
            _httpClient.DefaultRequestHeaders.Remove("X-Identity-Token");
            _httpClient.DefaultRequestHeaders.Add("X-Identity-Token", b2cToken);
            var result = await _httpClient.PostAsync("api/auth/b2c-login", null);
            
            if (result.IsSuccessStatusCode)
            {
                var response = await result.Content.ReadFromJsonAsync<AuthResponse>();
                if (response?.Success == true)
                {
                    await _tokenService.SaveTokenAsync(response.Token!);
                    return true;
                }
            }
            else 
            {
                var error = await result.Content.ReadAsStringAsync();
                Console.WriteLine($"[AUTH_DEBUG] B2C Exchange Failed: {result.StatusCode} - {error}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[AUTH_DEBUG] B2C Exchange Exception: {ex.Message}");
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
                
                var handler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
                var jwtToken = handler.ReadJwtToken(response.Token);
                var isAdmin = jwtToken.Claims.Any(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role) && 
                              jwtToken.Claims.Any(c => c.Value.Contains("Admin"));
                              
                await _tokenService.SaveTenantContextAsync(tenantId, associationId, isAdmin);
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
