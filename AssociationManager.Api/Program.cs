using AssociationManager.Api.Middlewares;
using AssociationManager.Auth.Interfaces;
using Hangfire;
using Hangfire.SqlServer;
using AssociationManager.Auth.Models;
using AssociationManager.Auth.Services;
using AssociationManager.Data;
using AssociationManager.Data.Interfaces;
using AssociationManager.Data.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using AssociationManager.Realtime.Hubs;
using AssociationManager.Services.Implementations;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using AssociationManager.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using System.Text;
using System.IdentityModel.Tokens.Jwt;
using Azure.Identity;
using Azure.Extensions.AspNetCore.Configuration.Secrets;

JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

var builder = WebApplication.CreateBuilder(args);

// Key Vault Integration
var keyVaultName = builder.Configuration["KeyVaultName"];
if (!string.IsNullOrEmpty(keyVaultName))
{
    var kvUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
    builder.Configuration.AddAzureKeyVault(kvUri, new DefaultAzureCredential());
    Console.WriteLine($"[BOOTSTRAP] Azure Key Vault configuration successfully loaded from: {kvUri}");
}

// Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Health Checks
var healthChecks = builder.Services.AddHealthChecks();

var defaultConnectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(defaultConnectionString))
{
    healthChecks.AddSqlServer(defaultConnectionString, name: "SQL Server");
}

var redisConnectionString = builder.Configuration["Redis:Configuration"];
if (!string.IsNullOrEmpty(redisConnectionString))
{
    healthChecks.AddRedis(redisConnectionString, name: "Redis");
}

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
builder.Services.AddScoped<DbConnectionFactory>();
builder.Services.AddScoped<ITenantRepository, TenantRepository>();
builder.Services.AddScoped<IGlobalUserRepository, GlobalUserRepository>();
builder.Services.AddScoped<IAssocUserRepository, AssocUserRepository>();
builder.Services.AddScoped<IUserRepository>(sp => sp.GetRequiredService<IAssocUserRepository>());
builder.Services.AddScoped<IAssociationRepository>(sp => new AssociationRepository(sp.GetRequiredService<DbConnectionFactory>(), sp.GetRequiredService<ITenantContext>(), "assoc"));
builder.Services.AddScoped<IAuditLogRepository, AuditLogRepository>();
builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<IAssetRepository, AssetRepository>();
builder.Services.AddScoped<IPersonRepository, PersonRepository>();
builder.Services.AddScoped<IOccupancyRepository, OccupancyRepository>();
builder.Services.AddScoped<IVehicleRepository, VehicleRepository>();
builder.Services.AddScoped<IPetRepository, PetRepository>();
builder.Services.AddScoped<IInvoiceRepository, InvoiceRepository>();
builder.Services.AddScoped<IBillingBatchRepository, BillingBatchRepository>();
builder.Services.AddScoped<IWorkOrderRepository, WorkOrderRepository>();
builder.Services.AddScoped<IBroadcastRepository, BroadcastRepository>();
builder.Services.AddScoped<ITariffRepository, TariffRepository>();
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
builder.Services.AddScoped<ISubscriptionRepository, SubscriptionRepository>();
builder.Services.AddScoped<IGovernanceRepository, GovernanceRepository>();
builder.Services.AddScoped<IPlatformBillingRepository, PlatformBillingRepository>();
builder.Services.AddScoped<IAuthWorkflowRepository, AuthWorkflowRepository>();
builder.Services.AddScoped<IFineRepository, FineRepository>();
builder.Services.AddScoped<IDashboardRepository, DashboardRepository>();
builder.Services.AddScoped<IRazorpayRepository, RazorpayRepository>();
builder.Services.AddScoped<IPlatformAccountRepository, PlatformAccountRepository>();
builder.Services.AddScoped<IReportingRepository, ReportingRepository>();
builder.Services.AddScoped<ICommunicationRepository, CommunicationRepository>();
builder.Services.AddScoped<IContentRepository, ContentRepository>();

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
builder.Services.AddScoped<IGovernanceService, GovernanceService>();
builder.Services.AddScoped<IPlatformBillingService, PlatformBillingService>();
builder.Services.AddScoped<IPaymentServiceV2, PaymentServiceV2>();
builder.Services.AddScoped<IFineService, FineService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IReportingService, ReportingService>();
builder.Services.AddScoped<IRuleEngineService, RuleEngineService>();
builder.Services.AddScoped<IInvoicePdfService, InvoicePdfService>();
builder.Services.AddScoped<IEmailTemplateService, EmailTemplateService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddHttpClient<AssociationManager.Services.Razorpay.RazorpayClient>();
builder.Services.AddScoped<AssociationManager.Services.Billing.BillingBatchService>();
builder.Services.AddScoped<AssociationManager.Services.Jobs.EmailDispatchJob>();
builder.Services.AddScoped<RulesEngineSeeder>();
builder.Services.AddScoped<IMaintenanceService, MaintenanceService>();
builder.Services.AddScoped<AssociationManager.Services.Jobs.BalanceSyncJob>();
// Billing Strategies & Batch Service
builder.Services.AddScoped<AssociationManager.Services.Billing.IBillingStrategy, AssociationManager.Services.Billing.FixedBillingStrategy>();
builder.Services.AddScoped<AssociationManager.Services.Billing.IBillingStrategy, AssociationManager.Services.Billing.AreaBasedBillingStrategy>();

// Hangfire Configuration
builder.Services.AddHangfire(configuration => configuration
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseSqlServerStorage(builder.Configuration.GetConnectionString("DefaultConnection"), new SqlServerStorageOptions
    {
        CommandBatchMaxTimeout = TimeSpan.FromMinutes(5),
        SlidingInvisibilityTimeout = TimeSpan.FromMinutes(5),
        QueuePollInterval = TimeSpan.FromMinutes(5),
        UseRecommendedIsolationLevel = true,
        DisableGlobalLocks = true
    }));

builder.Services.AddHangfireServer();

// Caching
builder.Services.AddDistributedMemoryCache();
builder.Services.AddMemoryCache();

// Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>() 
    ?? throw new InvalidOperationException("JwtSettings is missing from configuration.");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings.Issuer ?? throw new InvalidOperationException("JWT Issuer is missing"),
            ValidAudience = jwtSettings.Audience ?? throw new InvalidOperationException("JWT Audience is missing"),
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key ?? throw new InvalidOperationException("JWT Key is missing"))),
            RoleClaimType = "role",
            NameClaimType = "name"
        };
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
                logger.LogError("Association API Authentication failed: {Message}. Token info: {TokenHeader}", 
                    context.Exception.Message, 
                    context.Request.Headers.Authorization.ToString());
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
                logger.LogInformation("Token validated for {User}", context.Principal?.Identity?.Name);
                return Task.CompletedTask;
            }
        };
    });

// Real-time
builder.Services.AddSignalR();
/*
    .AddStackExchangeRedis(builder.Configuration.GetSection("Redis:Configuration").Value!);
*/

// CORS
var allowedOrigins = builder.Configuration["AllowedOrigins"]?.Split(',').Select(x => x.Trim()).ToArray() ?? new[] { "https://localhost:7001", "https://localhost:7011" };
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowClient", policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// Authorization Policies
builder.Services.AddScoped<IAuthorizationHandler, AssociationManager.Shared.Authorization.RoleLevelHandler>();
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireResident", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "RequireResident")));
    options.AddPolicy("RequireUserManager", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelUserManager, "RequireUserManager")));
    options.AddPolicy("RequireAssetManager", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssetManager, "RequireAssetManager")));
    options.AddPolicy("RequireFinanceManager", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "RequireFinanceManager")));
    options.AddPolicy("RequireManagement", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "RequireManagement"))); // Level 40+
    options.AddPolicy("RequireAssociationAdmin", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssociationAdmin, "RequireAssociationAdmin")));
    options.AddPolicy("RequireSystemAdmin", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelSystemAdmin, "RequireAdmin")));

    // --- MENU VISIBILITY POLICIES ---
    options.AddPolicy("ShowMenu_Assets", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Assets")));
    options.AddPolicy("ShowMenu_Finance", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Finance")));
    options.AddPolicy("ShowMenu_Operations", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Operations")));
    options.AddPolicy("ShowMenu_Users", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssociationAdmin, "ShowMenu_Users"))); // Level 80+
    options.AddPolicy("ShowMenu_Tariffs", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "ShowMenu_Tariffs"))); // Level 40+
    options.AddPolicy("ShowMenu_Community", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssociationAdmin, "ShowMenu_Community"))); // Level 80+
    options.AddPolicy("ShowMenu_Broadcasts", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "ShowMenu_Broadcasts"))); // Level 40+
    options.AddPolicy("ShowMenu_Governance", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowMenu_Governance")));
    options.AddPolicy("ShowMenu_Settings", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelPlatformAdmin, "ShowMenu_Settings"))); // Level 90+

    // --- DASHBOARD WIDGET POLICIES ---
    options.AddPolicy("ShowWidget_FinancialSummary", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_FinancialSummary")));
    options.AddPolicy("ShowWidget_ActiveRequests", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_ActiveRequests")));
    options.AddPolicy("ShowWidget_Announcements", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_Announcements")));
    options.AddPolicy("ShowWidget_AuditLog", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelAssetManager, "ShowWidget_AuditLog"))); // Level 60+
    options.AddPolicy("ShowWidget_Committee", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelResident, "ShowWidget_Committee")));
    options.AddPolicy("ShowWidget_Outstanding", policy => 
        policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelFinanceManager, "ShowWidget_Outstanding"))); // Level 40+
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<CorrelationIdMiddleware>();

app.UseHttpsRedirection();
app.UseCors("AllowClient");

// Fix 5: Enable WebSockets for stable SignalR handshake through gateway
app.UseWebSockets();

app.UseAuthentication();
app.UseAuthorization();
app.UseHangfireDashboard("/hangfire", new DashboardOptions
{
    Authorization = new[] { new AssociationManager.Api.Authorization.HangfireAuthorizationFilter() }
});

// Multi-tenancy

app.MapControllers();
app.MapHealthChecks("/health");
app.MapHub<AssociationManager.Realtime.Hubs.NotificationHub>("/hubs/notifications");

// Seed Rules Engine & Setup Jobs
var defaultConnectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(defaultConnectionString))
{
    try
    {
        Console.WriteLine("DEBUG: Seeding Rules Engine & Setting up Jobs...");
        using (var scope = app.Services.CreateScope())
        {
            var seeder = scope.ServiceProvider.GetRequiredService<RulesEngineSeeder>();
            await seeder.SeedAsync();

            // Setup Recurring Jobs
            var recurringJobManager = scope.ServiceProvider.GetRequiredService<IRecurringJobManager>();
            
            // Automated Email Dispatch (4 times a day: 6AM, 4PM, 6PM, 12 AM IST)
            recurringJobManager.AddOrUpdate<AssociationManager.Services.Jobs.EmailDispatchJob>(
                "automated-email-dispatch",
                job => job.ProcessPendingEmailsAsync(),
                "30 0,10,12,18 * * *");

            // Hourly Enterprise Balance Synchronization
            recurringJobManager.AddOrUpdate<AssociationManager.Services.Jobs.BalanceSyncJob>(
                "enterprise-balance-sync",
                job => job.ProcessAllAssociationsAsync(),
                Cron.Daily());
        }
        Console.WriteLine("DEBUG: Seeding and Jobs setup successfully.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[CRITICAL] Rules Engine Seeding or Job Setup failed: {ex.Message}");
    }
}
else
{
    Console.WriteLine("DEBUG: Skipping Seeding and Job setup (Connection string missing).");
}

app.Run();
