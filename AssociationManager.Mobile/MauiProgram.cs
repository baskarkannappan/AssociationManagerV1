using Microsoft.Extensions.Logging;
using Microsoft.Identity.Client;
using AssociationManager.Mobile.Services;
using Blazored.LocalStorage;
using Microsoft.AspNetCore.Components.Authorization;

namespace AssociationManager.Mobile;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
			});

		builder.Services.AddMauiBlazorWebView();

		// UI Component Library
		builder.Services.AddBlazorBootstrap();

		// Secure Services
		builder.Services.AddSingleton<MobileTokenStorageService>();
		builder.Services.AddScoped<MobileAuthService>();
		builder.Services.AddScoped<MobileAssociationService>();
		builder.Services.AddScoped<MobileDashboardService>();
		builder.Services.AddSingleton<IWebAuthenticator>(WebAuthenticator.Default);
		
		// Entra External ID (CIAM) Authentication
		var tenantName = "assocmgruat";
		var b2cAuthority = $"https://{tenantName}.ciamlogin.com";
		var b2cClientId = "b6769384-144c-4c59-a9f5-02c201d4e769";
		var redirectUri = $"msal{b2cClientId}://auth";

		builder.Services.AddSingleton<IPublicClientApplication>(sp =>
		{
			return PublicClientApplicationBuilder.Create(b2cClientId)
				.WithAuthority(b2cAuthority)
				.WithRedirectUri(redirectUri)
				.WithIosKeychainSecurityGroup("com.microsoft.adalcache")
				.Build();
		});

		builder.Services.AddAuthorizationCore();
		builder.Services.AddScoped<MobileAuthenticationStateProvider>();
		builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<MobileAuthenticationStateProvider>());

		// Networking
		// Pointing to the live Azure Gateway
		var gatewayUrl = "https://assocmgr-dev-gateway.yellowmoss-1aeb0444.centralindia.azurecontainerapps.io/"; 
		
		builder.Services.AddHttpClient("AuthClient", client => 
		{
			client.BaseAddress = new Uri(gatewayUrl);
		});

		builder.Services.AddHttpClient("GatewayClient", client => 
		{
			client.BaseAddress = new Uri(gatewayUrl);
		});

#if DEBUG
		builder.Services.AddBlazorWebViewDeveloperTools();
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}
}
