using AssociationManager.Client;
using AssociationManager.Client.Services;
using Blazored.LocalStorage;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

// Register Local Storage
builder.Services.AddBlazoredLocalStorage();

// Register Services
builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ApiService>();

// Base API URL (Gateway)
var gatewayUrl = "https://localhost:7000/"; // Gateway URL
builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri(gatewayUrl) });

// Realtime Service
builder.Services.AddScoped(sp => new RealtimeService(
    sp.GetRequiredService<TokenService>(), 
    $"{gatewayUrl}hubs/notifications"));

await builder.Build().RunAsync();
