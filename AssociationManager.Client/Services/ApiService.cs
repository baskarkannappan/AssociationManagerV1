using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Threading.Tasks;
using AssociationManager.Shared.Models;
using Microsoft.JSInterop;
using System;
using System.IO;
using System.Linq;

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
            var response = await _httpClient.GetAsync(url);
            
            if (response.IsSuccessStatusCode)
            {
                var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<T>>(new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                if (apiResponse != null && apiResponse.Success)
                {
                    return apiResponse.Data;
                }
                
                if (apiResponse != null && !string.IsNullOrEmpty(apiResponse.Message))
                {
                    Console.WriteLine($"API Error: {apiResponse.Message}");
                }
                return default;
            }
            else
            {
                var content = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"HTTP Error {response.StatusCode}: {content}");
                return default;
            }
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"HTTP Request Error: {ex.Message}");
            return default;
        }
        catch (System.Text.Json.JsonException ex)
        {
            Console.WriteLine($"JSON Deserialization Error: {ex.Message}");
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
                var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<TResponse>>(new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                return apiResponse != null ? apiResponse.Data : default;
            }
            else if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            {
                Console.WriteLine("API Error: 401 Unauthorized");
                throw new Exception("Session expired or unauthorized. Please login again.");
            }
            else if (response.StatusCode == System.Net.HttpStatusCode.Forbidden)
            {
                Console.WriteLine("API Error: 403 Forbidden");
                throw new Exception("You do not have permission to perform this action.");
            }
            else
            {
                // On other failures, try to read the error message if it's JSON, otherwise return status code
                string message = $"Server error: {response.StatusCode}";
                try 
                {
                    var errorResponse = await response.Content.ReadFromJsonAsync<ApiResponse>();
                    if (errorResponse != null && !string.IsNullOrEmpty(errorResponse.Message))
                        message = errorResponse.Message;
                }
                catch { /* Ignore parsing errors for error bodies */ }
                
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

    public async Task DownloadFileAsync(string url, string fileName, IJSRuntime jsRuntime)
    {
        try
        {
            var response = await _httpClient.GetAsync(url);
            if (response.IsSuccessStatusCode)
            {
                var bytes = await response.Content.ReadAsByteArrayAsync();
                var base64 = Convert.ToBase64String(bytes);
                var contentType = response.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";
                await jsRuntime.InvokeVoidAsync("downloadFileFromBase64", fileName, contentType, base64);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Download Error: {ex.Message}");
        }
    }

    public async Task<HttpResponseMessage> PostRawAsync<T>(string url, T data) => await _httpClient.PostAsJsonAsync(url, data);
    public async Task<HttpResponseMessage> PutRawAsync<T>(string url, T data) => await _httpClient.PutAsJsonAsync(url, data);
    public async Task<HttpResponseMessage> DeleteRawAsync(string url) => await _httpClient.DeleteAsync(url);
}
