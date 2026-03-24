using Blazored.LocalStorage;
using System.Threading.Tasks;
using System.Text.Json;
using System;

namespace AssociationManager.Client.Services;

public class TokenService
{
    private readonly ILocalStorageService _localStorage;
    private const string TokenKey = "authToken";
    private const string RefreshTokenKey = "refreshToken";

    public TokenService(ILocalStorageService localStorage)
    {
        _localStorage = localStorage;
    }

    public async Task SetTokens(string token, string refreshToken)
    {
        await _localStorage.SetItemAsync(TokenKey, token);
        await _localStorage.SetItemAsync(RefreshTokenKey, refreshToken);
    }

    public async Task<string?> GetToken() => await _localStorage.GetItemAsync<string>(TokenKey);
    public async Task<string?> GetRefreshToken() => await _localStorage.GetItemAsync<string>(RefreshTokenKey);

    public async Task RemoveTokens()
    {
        await _localStorage.RemoveItemAsync(TokenKey);
        await _localStorage.RemoveItemAsync(RefreshTokenKey);
    }

    public async Task<bool> IsTokenExpired()
    {
        var token = await GetToken();
        if (string.IsNullOrEmpty(token)) return true;

        try
        {
            var payload = token.Split('.')[1];
            var jsonBytes = ParseBase64WithoutPadding(payload);
            var keyValuePairs = JsonSerializer.Deserialize<Dictionary<string, object>>(jsonBytes);

            if (keyValuePairs != null && keyValuePairs.TryGetValue("exp", out var expValue))
            {
                var exp = long.Parse(expValue.ToString()!);
                var expDateTime = DateTimeOffset.FromUnixTimeSeconds(exp).UtcDateTime;
                return expDateTime < DateTime.UtcNow.AddMinutes(1); // Refresh 1 minute before expiry
            }
        }
        catch
        {
            return true;
        }
        return true;
    }

    private byte[] ParseBase64WithoutPadding(string base64)
    {
        switch (base64.Length % 4)
        {
            case 2: base64 += "=="; break;
            case 3: base64 += "="; break;
        }
        return Convert.FromBase64String(base64);
    }
}
