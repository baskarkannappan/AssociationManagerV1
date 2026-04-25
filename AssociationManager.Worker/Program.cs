using AssociationManager.Data;
using AssociationManager.Data.Interfaces;
using AssociationManager.Data.Repositories;
using AssociationManager.Services.Implementations;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using Hangfire;
using Hangfire.SqlServer;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Azure.Identity;
using Azure.Extensions.AspNetCore.Configuration.Secrets;

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

// Key Vault Integration
var keyVaultName = builder.Configuration["KeyVaultName"];
if (!string.IsNullOrEmpty(keyVaultName))
{
    var kvUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
    builder.Configuration.AddAzureKeyVault(kvUri, new DefaultAzureCredential());
    Console.WriteLine($"[BOOTSTRAP] Azure Key Vault configuration successfully loaded from: {kvUri}");
}

// Data Access
builder.Services.AddMemoryCache();
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSignalR();
builder.Services.AddScoped<DbConnectionFactory>();
builder.Services.AddHttpClient();
builder.Services.AddHttpContextAccessor();
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
builder.Services.AddScoped<ITariffRepository, TariffRepository>();
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
builder.Services.AddScoped<IAuthWorkflowRepository, AuthWorkflowRepository>();
builder.Services.AddScoped<IFineRepository, FineRepository>();
builder.Services.AddScoped<ICommunicationRepository, CommunicationRepository>();

// Services
builder.Services.AddScoped<BackgroundTenantContext>();
builder.Services.AddScoped<ITenantContext>(sp => sp.GetRequiredService<BackgroundTenantContext>());
builder.Services.AddScoped<IAuditService, AuditService>();
builder.Services.AddScoped<ILedgerService, LedgerService>();
builder.Services.AddScoped<IAssetService, AssetService>();
builder.Services.AddScoped<IPeopleService, PeopleService>();
builder.Services.AddScoped<IFinanceService, FinanceService>();
builder.Services.AddScoped<IFineService, FineService>();
builder.Services.AddScoped<IRuleEngineService, RuleEngineService>();
builder.Services.AddScoped<AssociationManager.Services.Billing.BillingBatchService>();
builder.Services.AddScoped<IMaintenanceService, MaintenanceService>();
builder.Services.AddScoped<IEmailTemplateService, EmailTemplateService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<AssociationManager.Services.Jobs.EmailDispatchJob>();
builder.Services.AddScoped<AssociationManager.Worker.Jobs.BalanceSyncJob>();

// Billing Strategies
builder.Services.AddScoped<AssociationManager.Services.Billing.IBillingStrategy, AssociationManager.Services.Billing.FixedBillingStrategy>();
builder.Services.AddScoped<AssociationManager.Services.Billing.IBillingStrategy, AssociationManager.Services.Billing.AreaBasedBillingStrategy>();

// Hangfire Configuration (Server)
builder.Services.AddHangfire(configuration => configuration
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseSqlServerStorage(builder.Configuration.GetConnectionString("DefaultConnection"), new SqlServerStorageOptions
    {
        CommandBatchMaxTimeout = TimeSpan.FromMinutes(5),
        SlidingInvisibilityTimeout = TimeSpan.FromMinutes(5),
        QueuePollInterval = TimeSpan.Zero,
        UseRecommendedIsolationLevel = true,
        DisableGlobalLocks = true
    }));

builder.Services.AddHangfireServer();

var host = builder.Build();

// Setup Recurring Jobs
using (var scope = host.Services.CreateScope())
{
    var recurringJobManager = scope.ServiceProvider.GetRequiredService<IRecurringJobManager>();
    // Daily Fine Accrual at 1:00 AM
    recurringJobManager.AddOrUpdate<IFinanceService>(
        "daily-fine-accrual",
        service => service.PostOverdueFinesAsync(),
        Cron.Daily(1));

    // Daily Database Archiving at 3:00 AM
    recurringJobManager.AddOrUpdate<IMaintenanceService>(
        "database-archiving",
        service => service.ArchiveAuditLogsAsync(180),
        Cron.Daily(3));

    // Automated Email Dispatch (4 times a day: 6AM, 4PM, 6PM, 12 AM IST)
    // Using UTC equivalents: 00:30, 10:30, 12:30, 18:30 UTC
    recurringJobManager.AddOrUpdate<AssociationManager.Services.Jobs.EmailDispatchJob>(
        "automated-email-dispatch",
        job => job.ProcessPendingEmailsAsync(),
        "30 0,10,12,18 * * *");

    // Hourly Enterprise Balance Synchronization
    recurringJobManager.AddOrUpdate<AssociationManager.Worker.Jobs.BalanceSyncJob>(
        "enterprise-balance-sync",
        job => job.ProcessAllAssociationsAsync(),
        Cron.Hourly());
}

var app = builder.Build();

app.MapGet("/", () => "Worker is running and healthy!");

app.Run();
