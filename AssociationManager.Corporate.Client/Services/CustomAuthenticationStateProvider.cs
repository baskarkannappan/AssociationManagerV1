using Microsoft.AspNetCore.Components.Authorization;
using System.Security.Claims;
using System.Text.Json;
using AssociationManager.Corporate.Client.Services;
using System.Net.Http.Headers;

namespace AssociationManager.Corporate.Client.Services;

public class CustomAuthenticationStateProvider : AuthenticationStateProvider
{
    private readonly TokenService _tokenService;
    private readonly HttpClient _httpClient;
    private readonly ClaimsPrincipal _anonymous = new(new ClaimsIdentity());

    public CustomAuthenticationStateProvider(TokenService tokenService, HttpClient httpClient)
    {
        _tokenService = tokenService;
        _httpClient = httpClient;
    }

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        var token = await _tokenService.GetToken();
        if (string.IsNullOrWhiteSpace(token))
        {
            return new AuthenticationState(_anonymous);
        }

        return new AuthenticationState(new ClaimsPrincipal(new ClaimsIdentity(ParseClaimsFromJwt(token), "jwt", "name", "role")));
    }

    public void NotifyUserAuthentication(string token)
    {
        var authenticatedUser = new ClaimsPrincipal(new ClaimsIdentity(ParseClaimsFromJwt(token), "jwt", "name", "role"));
        var authState = Task.FromResult(new AuthenticationState(authenticatedUser));
        NotifyAuthenticationStateChanged(authState);
    }

    public void NotifyUserLogout()
    {
        var authState = Task.FromResult(new AuthenticationState(_anonymous));
        NotifyAuthenticationStateChanged(authState);
    }

    private IEnumerable<Claim> ParseClaimsFromJwt(string jwt)
    {
        var payload = jwt.Split('.')[1];
        var jsonBytes = ParseBase64WithoutPadding(payload);
        var keyValuePairs = JsonSerializer.Deserialize<Dictionary<string, object>>(jsonBytes);
        
        var claims = new List<Claim>();
        if (keyValuePairs != null)
        {
            foreach (var kvp in keyValuePairs)
            {
                var key = kvp.Key;
                var value = kvp.Value;

                var isRoleKey = key.Equals("role", StringComparison.OrdinalIgnoreCase) || key.Equals(ClaimTypes.Role, StringComparison.OrdinalIgnoreCase) || key.Equals("Role", StringComparison.OrdinalIgnoreCase);
                if (isRoleKey && value is JsonElement roleElement && roleElement.ValueKind == JsonValueKind.Array)
                {
                    foreach (var role in roleElement.EnumerateArray())
                    {
                        claims.Add(new Claim("role", role.ToString()));
                    }
                }
                else if (isRoleKey)
                {
                    var roleStr = value.ToString()!;
                    if (roleStr.Contains(','))
                    {
                        foreach (var r in roleStr.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                        {
                            claims.Add(new Claim(ClaimTypes.Role, r));
                        }
                    }
                    else
                    {
                        claims.Add(new Claim("role", roleStr));
                    }
                }
                else if (key == "unique_name" || key == "name") claims.Add(new Claim("name", value.ToString()!));
                else if (key == "email") claims.Add(new Claim(ClaimTypes.Email, value.ToString()!));
                else if (key == "sub") claims.Add(new Claim(ClaimTypes.NameIdentifier, value.ToString()!));
                else claims.Add(new Claim(key, value.ToString()!));
            }
        }
        foreach (var claim in claims)
        {
            Console.WriteLine($"Parsed Claim: {claim.Type} - {claim.Value}");
        }
        return claims;
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
