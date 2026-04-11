using AssociationManager.Shared.Models;
using System.Net.Http.Json;
using System.Net.Http.Headers;

namespace AssociationManager.Mobile.Services;

public class MobileDashboardService
{
    private readonly HttpClient _httpClient;
    private readonly MobileTokenStorageService _tokenService;

    public MobileDashboardService(IHttpClientFactory httpClientFactory, MobileTokenStorageService tokenService)
    {
        _httpClient = httpClientFactory.CreateClient("GatewayClient");
        _tokenService = tokenService;
    }

    public async Task<AdminDashboardOverview?> GetAdminOverviewAsync()
    {
        var context = await _tokenService.GetTenantContextAsync();
        if (context.AssociationId == 0) return null;

        await AuthenticateRequestAsync();
        
        try
        {
            return await _httpClient.GetFromJsonAsync<AdminDashboardOverview>($"api/dashboard/admin/overview?associationId={context.AssociationId}");
        }
        catch
        {
            return null;
        }
    }

    public async Task<ResidentDashboardOverview?> GetResidentOverviewAsync()
    {
        await AuthenticateRequestAsync();
        try
        {
            return await _httpClient.GetFromJsonAsync<ResidentDashboardOverview>("api/dashboard/resident/overview");
        }
        catch
        {
            return null;
        }
    }

    private async Task AuthenticateRequestAsync()
    {
        var token = await _tokenService.GetTokenAsync();
        if (!string.IsNullOrEmpty(token))
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }
}
