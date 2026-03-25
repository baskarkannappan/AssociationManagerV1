# AssociationManagerSaaS - One Click Launch Script

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- Stopping existing processes ---" -ForegroundColor Cyan
Stop-Process -Name "dotnet" -Force
Stop-Process -Name "AssociationManager.Gateway" -Force
Stop-Process -Name "AssociationManager.Api" -Force
Stop-Process -Name "AssociationManager.Corporate.Api" -Force
Stop-Process -Name "AssociationManager.Realtime" -Force
Stop-Process -Name "AssociationManager.Gateway" -Force
Stop-Process -Name "AssociationManager.Client" -Force
Stop-Process -Name "AssociationManager.Corporate.Client" -Force

Write-Host "--- Building Solution ---" -ForegroundColor Cyan
dotnet build AssociationManagerSaaS.slnx --nologo -v q
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please fix errors before running." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "--- Starting Database Migrations ---" -ForegroundColor Cyan
dotnet run --project AssociationManager.Database\AssociationManager.Database.csproj
if ($LASTEXITCODE -ne 0) {
    Write-Host "Database migration failed! Please check the logs." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "--- Starting Services ---" -ForegroundColor Cyan

# 1. API
Write-Host "[1/6] Starting Association API (Port 5001)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Api\AssociationManager.Api.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 2. Corporate API
Write-Host "[2/6] Starting Corporate API (Port 7010)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Corporate.Api\AssociationManager.Corporate.Api.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 3. Realtime
Write-Host "[3/6] Starting Realtime Service (Port 6001)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Realtime\AssociationManager.Realtime.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 4. Gateway
Write-Host "[4/6] Starting API Gateway (Port 7000)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Gateway\AssociationManager.Gateway.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 5. Association Client
Write-Host "[5/6] Starting Association Client (Port 7001)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Client\AssociationManager.Client.csproj --no-build --launch-profile https" -WindowStyle Minimized

# 6. Corporate Client
Write-Host "[6/6] Starting Corporate Client (Port 7011)..."
Start-Process dotnet -ArgumentList "run --project AssociationManager.Corporate.Client\AssociationManager.Corporate.Client.csproj --no-build --launch-profile https" -WindowStyle Minimized

Write-Host "`nAll services initialized!" -ForegroundColor Green
Write-Host "Gateway:       https://localhost:7000"
Write-Host "Assoc Client:  https://localhost:7001" -ForegroundColor Yellow
Write-Host "Corp Client:   https://localhost:7011" -ForegroundColor Magenta
Write-Host "Corporate API: https://localhost:7010 (routed via Gateway)"
Write-Host "`nPlease wait a few seconds for the client to warm up, then refresh your browser."
