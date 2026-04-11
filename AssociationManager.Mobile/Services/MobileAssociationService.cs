using AssociationManager.Shared.DTOs;
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

    public async Task<List<AssociationDto>> GetMyAssociationsAsync()
    {
        var token = await _tokenService.GetTokenAsync();
        if (string.IsNullOrEmpty(token)) return new List<AssociationDto>();

        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        
        try
        {
            return await _httpClient.GetFromJsonAsync<List<AssociationDto>>("api/associations/my-tenants") ?? new List<AssociationDto>();
        }
        catch
        {
            return new List<AssociationDto>();
        }
    }
}
