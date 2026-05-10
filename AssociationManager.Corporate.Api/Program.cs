using AssociationManager.Auth.Interfaces;
using AssociationManager.Auth.Models;
using AssociationManager.Auth.Services;
using AssociationManager.Data;
using AssociationManager.Data.Interfaces;
using AssociationManager.Data.Repositories;
using AssociationManager.Shared.Interfaces;
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
using Microsoft.Identity.Web;

Console.WriteLine("[BOOTSTRAP] Corporate API starting...");

try
{
    JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

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

    // Application Insights (Conditional to prevent crash if connection string is missing)
    var aiConnString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
    if (!string.IsNullOrEmpty(aiConnString))
    {
        builder.Services.AddApplicationInsightsTelemetry(options => 
        {
            options.ConnectionString = aiConnString;
        });
        Console.WriteLine("[BOOTSTRAP] Application Insights telemetry enabled.");
    }
    else
    {
        Console.WriteLine("[BOOTSTRAP] WARNING: Application Insights connection string not found. Telemetry is disabled.");
    }

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

    // Data Access
    builder.Services.AddScoped<DbConnectionFactory>();
    builder.Services.AddScoped<ITenantRepository, TenantRepository>();
    builder.Services.AddScoped<IGlobalUserRepository, GlobalUserRepository>();
    builder.Services.AddScoped<IAssocUserRepository, AssocUserRepository>();
    builder.Services.AddScoped<IUserRepository>(sp => sp.GetRequiredService<IGlobalUserRepository>());
    builder.Services.AddScoped<IAssociationRepository>(sp => new AssociationRepository(sp.GetRequiredService<DbConnectionFactory>(), sp.GetRequiredService<ITenantContext>(), "corp"));
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
    builder.Services.AddScoped<RulesEngineSeeder>();
    builder.Services.AddScoped<IMaintenanceService, MaintenanceService>();

    // Billing Strategies
    builder.Services.AddScoped<AssociationManager.Services.Billing.IBillingStrategy, AssociationManager.Services.Billing.FixedBillingStrategy>();
    builder.Services.AddScoped<AssociationManager.Services.Billing.IBillingStrategy, AssociationManager.Services.Billing.AreaBasedBillingStrategy>();

    // Caching
    builder.Services.AddDistributedMemoryCache();
    builder.Services.AddMemoryCache();

    // Authentication - Dual Scheme (CIAM + Local Session)
    builder.Services.AddAuthentication(options => 
    {
        options.DefaultAuthenticateScheme = "LocalOrCIAM";
        options.DefaultChallengeScheme = "LocalOrCIAM";
    })
    .AddPolicyScheme("LocalOrCIAM", "LocalOrCIAM", options =>
    {
        options.ForwardDefaultSelector = context =>
        {
            string authorization = context.Request.Headers["Authorization"];
            if (string.IsNullOrEmpty(authorization)) return JwtBearerDefaults.AuthenticationScheme;
            
            // If the token is short or doesn't look like a CIAM token, try Local
            if (authorization.Contains("Bearer eyJ") && authorization.Length < 1000) return "Local";
            return JwtBearerDefaults.AuthenticationScheme;
        };
    })
    .AddJwtBearer("Local", options =>
    {
        var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>();
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtSettings.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtSettings.Audience,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key)),
            ClockSkew = TimeSpan.Zero
        };
    })
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        // CIAM Authority & Metadata (Read from Key Vault/Config)
        options.Authority = builder.Configuration["AzureAd:Authority"] ?? "https://0c8b323e-7dcf-4bf6-8eeb-3656cf1b673a.ciamlogin.com";
        options.MetadataAddress = builder.Configuration["AzureAd:MetadataAddress"] ?? $"{options.Authority}/0c8b323e-7dcf-4bf6-8eeb-3656cf1b673a/v2.0/.well-known/openid-configuration";
        
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuers = new[] 
            { 
                $"{options.Authority}/0c8b323e-7dcf-4bf6-8eeb-3656cf1b673a/v2.0",
                builder.Configuration["AzureAd:ValidIssuer"] ?? "REPLACE_IN_KEYVAULT"
            },
            ValidateAudience = true,
            ValidAudiences = new[] 
            { 
                builder.Configuration["AzureAd:ClientId"],
                "b6769384-144c-4c59-a9f5-02c201d4e769" // SPA client ID
            },
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
            
            options.Events = new JwtBearerEvents
            {
                OnAuthenticationFailed = context =>
                {
                    Console.WriteLine("[AUTH_FAILED] Exception: " + context.Exception.ToString());
                    return Task.CompletedTask;
                },
                OnTokenValidated = context =>
                {
                    Console.WriteLine("[AUTH_SUCCESS] Token validated for: " + context.Principal?.Identity?.Name);
                    return Task.CompletedTask;
                },
                OnChallenge = context =>
                {
                    var endpoint = context.HttpContext.GetEndpoint();
                    var allowAnon = endpoint?.Metadata.GetMetadata<Microsoft.AspNetCore.Authorization.IAllowAnonymous>();
                    if (allowAnon != null)
                    {
                        context.HandleResponse(); // Suppress 401 challenge on anonymous endpoints
                    }
                    else
                    {
                        Console.WriteLine("[AUTH_CHALLENGE] Error: " + context.Error + " | Desc: " + context.ErrorDescription);
                    }
                    return Task.CompletedTask;
                }
            };
        });

    // Real-time
    builder.Services.AddSignalR();

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
        options.FallbackPolicy = null;
        options.AddPolicy("RequireCorporate", policy => 
            policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelCorporateAuditor, "RequireCorporate")));
        options.AddPolicy("RequirePlatform", policy => 
            policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelPlatformAdmin, "RequirePlatform")));
        options.AddPolicy("RequirePlatformAdmin", policy => 
            policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelPlatformAdmin, "RequirePlatformAdmin")));
        options.AddPolicy("RequireSystemAdmin", policy => 
            policy.Requirements.Add(new AssociationManager.Shared.Authorization.RoleLevelRequirement(AppRole.LevelSystemAdmin, "RequireAdmin")));
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

    app.MapControllers();
    app.MapHealthChecks("/health");
    app.MapHub<AssociationManager.Realtime.Hubs.NotificationHub>("/hubs/notifications");

    // Seed Rules Engine
    if (!string.IsNullOrEmpty(defaultConnectionString))
    {
        try
        {
            Console.WriteLine("DEBUG: Seeding Rules Engine...");
            using (var scope = app.Services.CreateScope())
            {
                var seeder = scope.ServiceProvider.GetRequiredService<RulesEngineSeeder>();
                await seeder.SeedAsync();
            }
            Console.WriteLine("DEBUG: Rules Engine seeded successfully.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[CRITICAL] Rules Engine Seeding failed: {ex.Message}");
            // We allow the app to continue starting even if seeding fails
        }
    }
    else
    {
        Console.WriteLine("DEBUG: Skipping Rules Engine seeding (Connection string missing).");
    }

    Console.WriteLine("[BOOTSTRAP] Corporate API is starting app.Run()...");
    app.Run();
}
catch (Exception ex)
{
    Console.WriteLine($"[FATAL] Corporate API Startup Failed: {ex}");
    throw;
}
