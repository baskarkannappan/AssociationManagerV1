using AssociationManager.Shared.Models;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using AssociationManager.Mobile.Services;

namespace AssociationManager.Mobile.Services;

public class MobileAssociationService
{
    private readonly HttpClient _httpClient;
    private readonly MobileTokenStorageService _tokenService;

    public MobileAssociationService(IHttpClientFactory httpClientFactory, MobileTokenStorageService tokenService)
    {
        _httpClient = httpClientFactory.CreateClient("GatewayClient");
        _tokenService = tokenService;
    }

    public async Task<List<Association>> GetMyAssociationsAsync()
    {
        var token = await _tokenService.GetTokenAsync();
        if (string.IsNullOrEmpty(token)) return new List<Association>();

        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        
        try
        {
            var result = await _httpClient.GetFromJsonAsync<ApiResponse<IEnumerable<Association>>>("api/associations/my-tenants");
            return result?.Data?.ToList() ?? new List<Association>();
        }
        catch
        {
            return new List<Association>();
        }
    }
}
