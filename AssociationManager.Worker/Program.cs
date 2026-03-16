using Hangfire;

var builder = Host.CreateApplicationBuilder(args);

/*
builder.Services.AddHangfire(config => 
    config.UseSqlServerStorage(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddHangfireServer();
*/

builder.Services.AddHttpClient();

// Register services and repositories needed for jobs
// builder.Services.AddScoped<IAuthService, AuthService>();
// ...

var host = builder.Build();
host.Run();
