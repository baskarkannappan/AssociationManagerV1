using Microsoft.Extensions.Logging;
using AssociationManager.Mobile.Services;
using Blazored.LocalStorage;

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
		
		builder.Services.AddAuthorizationCore();
		builder.Services.AddScoped<MobileAuthenticationStateProvider>();
		builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<MobileAuthenticationStateProvider>());

		// Networking
		// NOTE: For Android Emulator, use 10.0.2.2 instead of localhost
		var gatewayUrl = "https://10.0.2.2:7000/"; 
		
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
