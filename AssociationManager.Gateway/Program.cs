using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;
using Azure.Identity;
using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Microsoft.AspNetCore.HttpOverrides;

Console.WriteLine("[BOOTSTRAP] Gateway starting...");

try
{
    var builder = WebApplication.CreateBuilder(args);

    // Key Vault Integration (Safe)
    var keyVaultName = builder.Configuration["KeyVaultName"];
    if (!string.IsNullOrEmpty(keyVaultName))
    {
        try
        {
            var kvUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
            builder.Configuration.AddAzureKeyVault(kvUri, new DefaultAzureCredential());
            Console.WriteLine($"[BOOTSTRAP] Azure Key Vault configuration successfully loaded from: {kvUri}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[BOOTSTRAP] WARNING: Failed to load Key Vault: {ex.Message}");
        }
    }

    // Application Insights
    builder.Services.AddApplicationInsightsTelemetry();

    // Health Checks
    builder.Services.AddHealthChecks();

    // Forwarded Headers for Azure Container Apps
    builder.Services.Configure<ForwardedHeadersOptions>(options =>
    {
        options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
        options.KnownNetworks.Clear();
        options.KnownProxies.Clear();
    });

    var allowedOrigins = builder.Configuration["AllowedOrigins"]?.Split(',').Select(x => x.Trim()).ToArray() 
        ?? new[] { "https://localhost:7001", "https://localhost:7011" };

    builder.Services.AddCors(options =>
    {
        options.AddPolicy("DefaultPolicy", policy =>
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        });
    });

    builder.Services.AddRateLimiter(options =>
    {
        options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

        options.AddPolicy("fixed", httpContext => 
            RateLimitPartition.GetFixedWindowLimiter(
                partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
                factory: _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 50,
                    Window = TimeSpan.FromSeconds(10),
                    QueueLimit = 5,
                    QueueProcessingOrder = QueueProcessingOrder.OldestFirst
                }));
        
        options.OnRejected = async (context, token) =>
        {
            await context.HttpContext.Response.WriteAsync("Too many requests. Please try again later.", cancellationToken: token);
        };
    });

    var proxyConfig = builder.Configuration.GetSection("ReverseProxy");
    if (proxyConfig.Exists())
    {
        builder.Services.AddReverseProxy()
            .LoadFromConfig(proxyConfig);
    }

    var app = builder.Build();

    app.UseForwardedHeaders();

    if (!app.Environment.IsDevelopment())
    {
        app.UseHsts();
    }

    app.Use(async (context, next) =>
    {
        context.Response.Headers.Append("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://accounts.google.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https:; frame-ancestors 'none';");
        context.Response.Headers.Append("X-Frame-Options", "DENY");
        context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
        context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
        
        await next();
    });

    app.UseCors("DefaultPolicy");
    app.UseWebSockets();
    app.UseRateLimiter();

    app.MapHealthChecks("/health");

    if (proxyConfig.Exists())
    {
        app.MapReverseProxy();
    }

    Console.WriteLine("[BOOTSTRAP] Gateway is running app.Run()...");
    app.Run();
}
catch (Exception ex)
{
    Console.WriteLine($"[FATAL] Gateway Startup Failed: {ex}");
    throw;
}
