using Microsoft.AspNetCore.Components.Authorization;
using System.Security.Claims;
using System.Text.Json;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Corporate.Client.Services;
using System.Net.Http.Headers;

namespace AssociationManager.Corporate.Client.Services;

public class CustomAuthenticationStateProvider : AuthenticationStateProvider
{
    private readonly TokenService _tokenService;
    private readonly ITenantContext _tenantContext;
    private readonly ClaimsPrincipal _anonymous = new(new ClaimsIdentity());

    public CustomAuthenticationStateProvider(TokenService tokenService, ITenantContext tenantContext)
    {
        _tokenService = tokenService;
        _tenantContext = tenantContext;
    }

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        var token = await _tokenService.GetToken();
        if (string.IsNullOrWhiteSpace(token))
        {
            return new AuthenticationState(_anonymous);
        }

        var claims = ParseClaimsFromJwt(token);
        UpdateTenantContext(claims);
        return new AuthenticationState(new ClaimsPrincipal(new ClaimsIdentity(claims, "jwt", "name", "role")));
    }

    public void NotifyUserAuthentication(string token)
    {
        var claims = ParseClaimsFromJwt(token);
        UpdateTenantContext(claims);
        var authenticatedUser = new ClaimsPrincipal(new ClaimsIdentity(claims, "jwt", "name", "role"));
        var authState = Task.FromResult(new AuthenticationState(authenticatedUser));
        NotifyAuthenticationStateChanged(authState);
    }

    private void UpdateTenantContext(IEnumerable<Claim> claims)
    {
        if (_tenantContext is ClientTenantContext context)
        {
            // Robust parsing for Corporate/Tenant ID restoration
            var tidClaim = claims.FirstOrDefault(c => 
                c.Type.Equals("TenantId", StringComparison.OrdinalIgnoreCase) || 
                c.Type.Equals("tenant_id", StringComparison.OrdinalIgnoreCase) ||
                c.Type.Equals("tid", StringComparison.OrdinalIgnoreCase))?.Value;
            if (int.TryParse(tidClaim, out int tid)) context.TenantId = tid;

            var aidClaim = claims.FirstOrDefault(c => 
                c.Type.Equals("AssociationId", StringComparison.OrdinalIgnoreCase) || 
                c.Type.Equals("association_id", StringComparison.OrdinalIgnoreCase) ||
                c.Type.Equals("aid", StringComparison.OrdinalIgnoreCase))?.Value;
            if (int.TryParse(aidClaim, out int aid)) context.AssociationId = aid;

            var uidClaim = claims.FirstOrDefault(c => 
                c.Type.Equals("UserId", StringComparison.OrdinalIgnoreCase) || 
                c.Type.Equals("user_id", StringComparison.OrdinalIgnoreCase) ||
                c.Type.Equals("uid", StringComparison.OrdinalIgnoreCase))?.Value;
            if (int.TryParse(uidClaim, out int uid)) context.UserId = uid;

            context.Email = claims.FirstOrDefault(c => 
                c.Type.Equals("email", StringComparison.OrdinalIgnoreCase) ||
                c.Type.Equals(ClaimTypes.Email, StringComparison.OrdinalIgnoreCase))?.Value;
            
            var roles = claims.Where(c => c.Type == "role" || c.Type == ClaimTypes.Role).Select(c => c.Value).ToHashSet();
            context.IsPlatformAdmin = roles.Contains("PlatformAdmin");
            context.IsSystemAdmin = roles.Contains("SystemAdmin");

            Console.WriteLine($"[CorporateAuth] Session Restored - User: {context.Email}, TenantId: {context.TenantId}, AssociationId: {context.AssociationId}");
        }
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
