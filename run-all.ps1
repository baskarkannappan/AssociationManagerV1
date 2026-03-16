# AssociationManagerSaaS - One Click Launch Script

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- Stopping existing processes ---" -ForegroundColor Cyan
Stop-Process -Name "dotnet" -Force
Stop-Process -Name "AssociationManager.Gateway" -Force
Stop-Process -Name "AssociationManager.Api" -Force
Stop-Process -Name "AssociationManager.Realtime" -Force

Write-Host "--- Building Solution ---" -ForegroundColor Cyan
dotnet build AssociationManagerSaaS.slnx --nologo -v q
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please fix errors before running." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "--- Starting Services ---" -ForegroundColor Cyan

# 1. API
Write-Host "[1/4] Starting API Service (Port 5001)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Api\AssociationManager.Api.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 2. Realtime
Write-Host "[2/4] Starting Realtime Service (Port 6001)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Realtime\AssociationManager.Realtime.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 3. Gateway
Write-Host "[3/4] Starting API Gateway (Port 7000)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Gateway\AssociationManager.Gateway.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 4. Client
Write-Host "[4/4] Starting Blazor Client (Port 7001)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Client\AssociationManager.Client.csproj --no-build --launch-profile https" -WindowStyle Minimized

Write-Host "`nAll services initialized!" -ForegroundColor Green
Write-Host "Gateway: https://localhost:7000"
Write-Host "Client:  https://localhost:7001" -ForegroundColor Yellow
Write-Host "`nPlease wait a few seconds for the client to warm up, then refresh your browser."
