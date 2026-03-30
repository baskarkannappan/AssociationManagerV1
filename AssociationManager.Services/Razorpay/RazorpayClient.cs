using AssociationManager.Shared.Models;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace AssociationManager.Services.Razorpay;

public class RazorpayClient
{
    private readonly HttpClient _httpClient;

    public RazorpayClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<string> CreateOrderAsync(decimal amount, string currency, string receipt, string keyId, string keySecret, object? notes = null)
    {
        var authHeader = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{keyId}:{keySecret}"));
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authHeader);

        var payload = new
        {
            amount = (int)(amount * 100), // Razorpay expects amount in paise
            currency = currency,
            receipt = receipt,
            notes = notes
        };

        var response = await _httpClient.PostAsJsonAsync("https://api.razorpay.com/v1/orders", payload);
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(content);
        return doc.RootElement.GetProperty("id").GetString() ?? throw new Exception("Failed to get Order ID from Razorpay");
    }

    public bool VerifySignature(string orderId, string paymentId, string signature, string keySecret)
    {
        var payload = $"{orderId}|{paymentId}";
        var secretBytes = Encoding.UTF8.GetBytes(keySecret);
        var payloadBytes = Encoding.UTF8.GetBytes(payload);

        using var hmac = new HMACSHA256(secretBytes);
        var hashBytes = hmac.ComputeHash(payloadBytes);
        var hash = BitConverter.ToString(hashBytes).Replace("-", "").ToLower();

        return hash == signature.ToLower();
    }

    public async Task<JsonElement> GetPaymentDetailsAsync(string paymentId, string keyId, string keySecret)
    {
        var authHeader = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{keyId}:{keySecret}"));
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authHeader);

        var response = await _httpClient.GetAsync($"https://api.razorpay.com/v1/payments/{paymentId}");
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        return JsonDocument.Parse(content).RootElement;
    }

    public bool VerifyWebhookSignature(string payload, string signature, string webhookSecret)
    {
        var secretBytes = Encoding.UTF8.GetBytes(webhookSecret);
        var payloadBytes = Encoding.UTF8.GetBytes(payload);

        using var hmac = new HMACSHA256(secretBytes);
        var hashBytes = hmac.ComputeHash(payloadBytes);
        var hash = BitConverter.ToString(hashBytes).Replace("-", "").ToLower();

        return hash == signature.ToLower();
    }
}
