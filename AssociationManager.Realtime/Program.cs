using AssociationManager.Realtime.Hubs;

var builder = WebApplication.CreateBuilder(args);

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
        policy.WithOrigins("https://localhost:7001", "http://localhost:5001") // Placeholder for client URLs
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

var app = builder.Build();

app.UseCors("DefaultPolicy");

app.MapHub<NotificationHub>("/hubs/notifications");

app.Run();
