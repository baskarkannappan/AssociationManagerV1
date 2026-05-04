using AssociationManager.Realtime.Hubs;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Key Vault Integration
var keyVaultName = builder.Configuration["KeyVaultName"];
if (!string.IsNullOrEmpty(keyVaultName))
{
    var kvUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
    builder.Configuration.AddAzureKeyVault(kvUri, new DefaultAzureCredential());
    Console.WriteLine($"[BOOTSTRAP] Azure Key Vault configuration successfully loaded from: {kvUri}");
}

// Add services to the container
builder.Services.AddSignalR();
/*
    .AddStackExchangeRedis(builder.Configuration.GetConnectionString("Redis") ?? "localhost", options => {
        options.Configuration.ChannelPrefix = "AssociationManager";
    });
*/

builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultPolicy", policy =>
    {
        policy.WithOrigins("https://localhost:7001", "http://localhost:5001", "https://localhost:7011") // Placeholder for client URLs
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

var app = builder.Build();

app.UseCors("DefaultPolicy");

app.MapHub<NotificationHub>("/hubs/notifications");

app.Run();
