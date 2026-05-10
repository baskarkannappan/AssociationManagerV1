using Microsoft.JSInterop;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class AnalyticsService
{
    private readonly IJSRuntime _js;
    private const string MeasurementId = "G-9JD8SHPC9P";

    public AnalyticsService(IJSRuntime js)
    {
        _js = js;
    }

    public async Task TrackPageView(string title, string url)
    {
        await _js.InvokeVoidAsync("analytics.trackPageView", title, url);
    }

    public async Task SetUserId(string email)
    {
        await _js.InvokeVoidAsync("analytics.setUserId", email);
    }
}
