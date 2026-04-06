using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;

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
            var response = await _httpClient.GetFromJsonAsync<ApiResponse<T>>(url);
            if (response != null && response.Success)
            {
                return response.Data;
            }
            
            if (response != null && !string.IsNullOrEmpty(response.Message))
            {
                Console.WriteLine($"API Error: {response.Message}");
            }
            return default;
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"HTTP Error: {ex.Message}");
            return default;
        }
    }

    public async Task<TResponse?> PostAsync<TRequest, TResponse>(string url, TRequest data)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync(url, data);
            
            if (response.IsSuccessStatusCode)
            {
                var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<TResponse>>();
                return apiResponse != null ? apiResponse.Data : default;
            }
            else
            {
                // On failure, deserialize as non-generic ApiResponse to safely read the Message
                var errorResponse = await response.Content.ReadFromJsonAsync<ApiResponse>();
                var message = errorResponse?.Message ?? $"Server error: {response.StatusCode}";
                Console.WriteLine($"API Error: {message}");
                throw new Exception(message);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"HTTP POST error: {ex.Message}");
            throw;
        }
    }

    public async Task<bool> PostAsync<TRequest>(string url, TRequest data)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync(url, data);
            if (response.IsSuccessStatusCode)
            {
                var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse>();
                return apiResponse?.Success ?? false;
            }
            return false;
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"POST Error: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> PutAsync<TRequest>(string url, TRequest data)
    {
        try
        {
            var response = await _httpClient.PutAsJsonAsync(url, data);
            if (response.IsSuccessStatusCode)
            {
                var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse>();
                return apiResponse?.Success ?? false;
            }
            return false;
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"PUT Error: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> DeleteAsync(string url)
    {
        try
        {
            var response = await _httpClient.DeleteAsync(url);
            if (response.IsSuccessStatusCode)
            {
                var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse>();
                return apiResponse?.Success ?? false;
            }
            return false;
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"DELETE Error: {ex.Message}");
            return false;
        }
    }

    public async Task<HttpResponseMessage> PostRawAsync<T>(string url, T data) => await _httpClient.PostAsJsonAsync(url, data);
    public async Task<HttpResponseMessage> PutRawAsync<T>(string url, T data) => await _httpClient.PutAsJsonAsync(url, data);
    public async Task<HttpResponseMessage> DeleteRawAsync(string url) => await _httpClient.DeleteAsync(url);
}
