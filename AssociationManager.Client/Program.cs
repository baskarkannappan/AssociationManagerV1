using AssociationManager.Client;
using AssociationManager.Client.Services;
using Blazored.LocalStorage;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using Microsoft.AspNetCore.Components.Authorization;
using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Enums;
using AssociationManager.Shared.Authorization;

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
builder.Services.AddScoped<IAuthorizationHandler, AssociationManager.Shared.Authorization.RoleLevelHandler>();
builder.Services.AddAuthorizationCore(options =>
{
    options.AddPolicy("RequireResident", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident)));
    options.AddPolicy("RequireUserManager", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelUserManager)));
    options.AddPolicy("RequireAssetManager", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssetManager)));
    options.AddPolicy("RequireFinanceManager", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager)));
    options.AddPolicy("RequireAssociationAdmin", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssociationAdmin)));
    options.AddPolicy("RequireSystemAdmin", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelSystemAdmin)));

    // --- MENU VISIBILITY POLICIES ---
    options.AddPolicy("ShowMenu_Assets", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Assets")));
    options.AddPolicy("ShowMenu_Finance", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Finance")));
    options.AddPolicy("ShowMenu_Operations", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Operations")));
    options.AddPolicy("ShowMenu_Users", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssociationAdmin, "ShowMenu_Users")));
    options.AddPolicy("ShowMenu_Tariffs", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "ShowMenu_Tariffs")));
    options.AddPolicy("ShowMenu_Community", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssociationAdmin, "ShowMenu_Community")));
    options.AddPolicy("ShowMenu_Broadcasts", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "ShowMenu_Broadcasts")));
    options.AddPolicy("ShowMenu_Governance", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Governance")));
    options.AddPolicy("ShowMenu_Settings", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelPlatformAdmin, "ShowMenu_Settings")));

    // --- DASHBOARD WIDGET POLICIES ---
    options.AddPolicy("ShowWidget_FinancialSummary", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_FinancialSummary")));
    options.AddPolicy("ShowWidget_ActiveRequests", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_ActiveRequests")));
    options.AddPolicy("ShowWidget_Announcements", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_Announcements")));
    options.AddPolicy("ShowWidget_AuditLog", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssetManager, "ShowWidget_AuditLog")));
    options.AddPolicy("ShowWidget_Committee", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_Committee")));
    options.AddPolicy("ShowWidget_Outstanding", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "ShowWidget_Outstanding")));
});

// Register Services
builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<ApiService>();
builder.Services.AddScoped<IAppAuthorizationService, AppAuthorizationService>();
builder.Services.AddScoped<IRuleEngineService, ClientRuleEngineService>();
builder.Services.AddScoped<ITenantContext, ClientTenantContext>();
builder.Services.AddScoped<GovernanceService>();
builder.Services.AddTransient<AuthHeaderHandler>();

// Base API URL (Gateway)
var gatewayUrl = builder.Configuration["GatewayUrl"] ?? "https://localhost:7000/"; // Gateway URL
builder.Services.AddHttpClient("AuthClient", client => 
{
    client.BaseAddress = new Uri(gatewayUrl);
});

builder.Services.AddHttpClient("GatewayClient", client => 
    {
        client.BaseAddress = new Uri(gatewayUrl);
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
