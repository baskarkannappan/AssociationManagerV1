using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Azure.Identity;
using System;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration((context, configBuilder) =>
    {
        var builtConfig = configBuilder.Build();
        var keyVaultName = builtConfig["KeyVaultName"];
        if (!string.IsNullOrEmpty(keyVaultName))
        {
            var kvUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
            configBuilder.AddAzureKeyVault(kvUri, new DefaultAzureCredential());
            Console.WriteLine($"[BOOTSTRAP] Azure Key Vault configuration successfully loaded from: {kvUri}");
        }
    })
    .Build();

host.Run();
