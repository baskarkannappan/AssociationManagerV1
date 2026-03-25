using AssociationManager.Corporate.Client;
using AssociationManager.Corporate.Client.Services;
using Blazored.LocalStorage;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using Microsoft.AspNetCore.Components.Authorization;
using System.Globalization;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Authorization;
using Microsoft.AspNetCore.Authorization;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

// Register Local Storage
builder.Services.AddBlazoredLocalStorage();

// Register Blazor Bootstrap
builder.Services.AddBlazorBootstrap();

// Auth States
builder.Services.AddOptions();
builder.Services.AddAuthorizationCore();
builder.Services.AddScoped<CustomAuthenticationStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<CustomAuthenticationStateProvider>());

// Authorization Policies
builder.Services.AddScoped<IAuthorizationHandler, AssociationManager.Shared.Authorization.RoleHandler>();
builder.Services.AddAuthorizationCore(options =>
{
    options.AddPolicy("RequireCorporate", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleRequirement(
            AppRole.PlatformAdmin, AppRole.SystemAdmin, AppRole.CorporateManager, 
            AppRole.SubscriptionManager, AppRole.GlobalUserManager, AppRole.CorporateAuditor)));

    options.AddPolicy("RequireManagement", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleRequirement(AppRole.PlatformAdmin, AppRole.CorporateManager)));

    options.AddPolicy("RequirePlanManagement", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleRequirement(AppRole.PlatformAdmin, AppRole.SubscriptionManager)));

    options.AddPolicy("RequireUserManagement", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleRequirement(AppRole.PlatformAdmin, AppRole.SystemAdmin, AppRole.GlobalUserManager)));

    options.AddPolicy("RequirePlatformAdmin", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleRequirement(AppRole.PlatformAdmin)));
});

// Register Services
builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ApiService>();
builder.Services.AddScoped<IAppAuthorizationService, AppAuthorizationService>();
builder.Services.AddTransient<AuthHeaderHandler>();

// Base API URL (Gateway)
var gatewayUrl = builder.Configuration["GatewayUrl"] ?? "https://localhost:7000/";
var baseApiUrl = gatewayUrl.EndsWith("/") ? $"{gatewayUrl}api/corporate/" : $"{gatewayUrl}/api/corporate/";

builder.Services.AddHttpClient("AuthClient", client => 
{
    client.BaseAddress = new Uri(gatewayUrl);
});

builder.Services.AddHttpClient("GatewayClient", client => 
    {
        client.BaseAddress = new Uri(baseApiUrl);
    })
    .AddHttpMessageHandler<AuthHeaderHandler>();

builder.Services.AddScoped(sp => sp.GetRequiredService<IHttpClientFactory>().CreateClient("GatewayClient"));

// Realtime Service
builder.Services.AddScoped(sp => new RealtimeService(
    sp.GetRequiredService<TokenService>(), 
    $"{gatewayUrl}hubs/notifications"));

var host = builder.Build();
var culture = new CultureInfo("en-IN");
CultureInfo.DefaultThreadCurrentCulture = culture;
CultureInfo.DefaultThreadCurrentUICulture = culture;
await host.RunAsync();
