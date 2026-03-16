using System.Net.Http;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components.Authorization;
using AssociationManager.Shared.DTOs;

namespace AssociationManager.Client.Services
{
    public class AuthService
    {
        private readonly HttpClient _http;
        private readonly AuthenticationStateProvider _authStateProvider;

        public AuthService(HttpClient http, AuthenticationStateProvider authStateProvider)
        {
            _http = http;
            _authStateProvider = authStateProvider;
        }

        public async Task<bool> LoginWithGoogle(string googleToken)
        {
            var response = await _http.PostAsJsonAsync("api/auth/google-login", googleToken);
            if (response.IsSuccessStatusCode)
            {
                var authResult = await response.Content.ReadFromJsonAsync<AuthResponse>();
                // In a real app, save to localStorage and notify state provider
                return true;
            }
            return false;
        }

        public async Task Logout()
        {
            await _http.PostAsync("api/auth/logout", null);
            // In a real app, clear localStorage and notify state provider
        }
    }
}
