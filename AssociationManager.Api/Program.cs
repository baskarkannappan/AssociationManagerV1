using AssociationManager.Auth.Interfaces;
using AssociationManager.Auth.Models;
using AssociationManager.Auth.Services;
using AssociationManager.Data;
using AssociationManager.Data.Interfaces;
using AssociationManager.Data.Repositories;
using AssociationManager.Realtime.Hubs;
using AssociationManager.Services.Implementations;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .CreateLogger();
builder.Host.UseSerilog();

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Auth Settings
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("JwtSettings"));
builder.Services.Configure<GoogleSettings>(builder.Configuration.GetSection("GoogleSettings"));

// Data Access
builder.Services.AddSingleton<DbConnectionFactory>();
builder.Services.AddScoped<ITenantRepository, TenantRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IAssociationRepository, AssociationRepository>();
builder.Services.AddScoped<IAuditLogRepository, AuditLogRepository>();
builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<IAssetRepository, AssetRepository>();
builder.Services.AddScoped<IPersonRepository, PersonRepository>();
builder.Services.AddScoped<IOccupancyRepository, OccupancyRepository>();
builder.Services.AddScoped<IVehicleRepository, VehicleRepository>();
builder.Services.AddScoped<IPetRepository, PetRepository>();
builder.Services.AddScoped<IInvoiceRepository, InvoiceRepository>();
builder.Services.AddScoped<IWorkOrderRepository, WorkOrderRepository>();
builder.Services.AddScoped<IBroadcastRepository, BroadcastRepository>();
builder.Services.AddScoped<ITariffRepository, TariffRepository>();
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
builder.Services.AddScoped<ISubscriptionRepository, SubscriptionRepository>();

// Services
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ITenantContext, TenantContext>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAssociationService, AssociationService>();
builder.Services.AddScoped<IAuditService, AuditService>();
builder.Services.AddScoped<ILedgerService, LedgerService>();
builder.Services.AddScoped<IAssetService, AssetService>();
builder.Services.AddScoped<IPeopleService, PeopleService>();
builder.Services.AddScoped<IFinanceService, FinanceService>();
builder.Services.AddScoped<IOperationsService, OperationsService>();
builder.Services.AddScoped<ICommunicationsService, CommunicationsService>();
builder.Services.AddScoped<ITariffService, TariffService>();
builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();

// Caching
builder.Services.AddDistributedMemoryCache();
/*
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetSection("Redis:Configuration").Value;
});
*/

// Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>() 
    ?? throw new InvalidOperationException("JwtSettings is missing from configuration.");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings.Issuer ?? throw new InvalidOperationException("JWT Issuer is missing"),
            ValidAudience = jwtSettings.Audience ?? throw new InvalidOperationException("JWT Audience is missing"),
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key ?? throw new InvalidOperationException("JWT Key is missing")))
        };
    });

// Real-time
builder.Services.AddSignalR();
/*
    .AddStackExchangeRedis(builder.Configuration.GetSection("Redis:Configuration").Value!);
*/

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowClient", policy =>
    {
        policy.WithOrigins("https://localhost:7001") // Client URL
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowClient");

app.UseAuthentication();
app.UseAuthorization();

// Multi-tenancy

app.MapControllers();
app.MapHub<AssociationManager.Realtime.Hubs.NotificationHub>("/hubs/notifications");

app.Run();
