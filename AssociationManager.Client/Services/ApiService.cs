using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace AssociationManager.Client.Services;

public class ApiService
{
    private readonly HttpClient _httpClient;
    public ApiService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<T?> GetAsync<T>(string url)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<T>(url);
        }
        catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.Unauthorized)
        {
            // Log and potentially trigger logout or redirect
            Console.WriteLine("401 Unauthorized: Session may have expired.");
            throw;
        }
    }

    public async Task<HttpResponseMessage> PostAsync<T>(string url, T data)
    {
        var response = await _httpClient.PostAsJsonAsync(url, data);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
        {
             Console.WriteLine("401 Unauthorized: Post failed.");
        }
        return response;
    }

    public async Task<HttpResponseMessage> PutAsync<T>(string url, T data)
    {
        var response = await _httpClient.PutAsJsonAsync(url, data);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
        {
             Console.WriteLine("401 Unauthorized: Put failed.");
        }
        return response;
    }

    public async Task<HttpResponseMessage> DeleteAsync(string url)
    {
        var response = await _httpClient.DeleteAsync(url);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
        {
             Console.WriteLine("401 Unauthorized: Delete failed.");
        }
        return response;
    }
}
