# apply-local-settings.ps1
# This script applies the local development settings to all projects in the solution.

$localSettingsPath = "localappsettings.json"
if (-not (Test-Path $localSettingsPath)) {
    Write-Error "localappsettings.json not found in root!"
    exit
}

$settings = Get-Content $localSettingsPath | ConvertFrom-Json

# 1. Apply to Main API
Write-Host "Applying to AssociationManager.Api..."
$settings | ConvertTo-Json -Depth 10 | Out-File "AssociationManager.Api/appsettings.Development.json" -Encoding utf8

# 2. Apply to Corporate API
Write-Host "Applying to AssociationManager.Corporate.Api..."
$settings | ConvertTo-Json -Depth 10 | Out-File "AssociationManager.Corporate.Api/appsettings.Development.json" -Encoding utf8

# 3. Apply to Gateway (Merging with existing Proxy settings)
Write-Host "Applying to AssociationManager.Gateway..."
$gatewayPath = "AssociationManager.Gateway/appsettings.json"
if (Test-Path $gatewayPath) {
    $gatewayBase = Get-Content $gatewayPath | ConvertFrom-Json
    $settings.ReverseProxy = $gatewayBase.ReverseProxy # Preserve the routes
    $settings | ConvertTo-Json -Depth 10 | Out-File "AssociationManager.Gateway/appsettings.Development.json" -Encoding utf8
}

# 4. Apply to Azure Functions (local.settings.json format)
Write-Host "Applying to AssociationManager.Functions.Email..."
$funcSettings = @{
    IsEncrypted = $false
    Values = @{
        AzureWebJobsStorage = "UseDevelopmentStorage=true"
        FUNCTIONS_WORKER_RUNTIME = "dotnet-isolated"
        "Smtp:Host" = $settings.Smtp.Host
        "Smtp:Port" = $settings.Smtp.Port
        "Smtp:Username" = $settings.Smtp.Username
        "Smtp:Password" = $settings.Smtp.Password
        "Smtp:FromEmail" = $settings.Smtp.FromEmail
        "Smtp:FromName" = $settings.Smtp.FromName
    }
}
$funcSettings | ConvertTo-Json -Depth 10 | Out-File "AssociationManager.Functions.Email/local.settings.json" -Encoding utf8

Write-Host "Done! All projects are now configured for local development." -ForegroundColor Green
