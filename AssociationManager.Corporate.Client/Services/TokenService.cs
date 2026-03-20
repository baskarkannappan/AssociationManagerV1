using Blazored.LocalStorage;
using System.Threading.Tasks;

namespace AssociationManager.Corporate.Client.Services;

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
}
