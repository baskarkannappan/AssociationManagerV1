# maintenance_mode.ps1
# Usage: .\maintenance_mode.ps1 -Mode Sleep (or Wakeup)

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Sleep", "Wakeup")]
    [string]$Mode
)

$ResourceGroup = "rg-assocmgr-dev"
$Apps = @("assocmgr-dev-api", "assocmgr-dev-corp-api", "assocmgr-dev-gateway")

if ($Mode -eq "Sleep") {
    Write-Host "Putting environment to sleep..." -ForegroundColor Cyan
    foreach ($app in $Apps) {
        Write-Host "Scaling $app to 0 replicas..."
        az containerapp revision label add --name $app --resource-group $ResourceGroup --label "sleeping" --no-wait
        # Note: Actual scaling to 0 is handled by the 'min-replicas' setting in Bicep, 
        # but manually stopping or scaling via CLI ensures no cold starts trigger.
        az containerapp update --name $app --resource-group $ResourceGroup --min-replicas 0 --max-replicas 0
    }
    
    Write-Host "Scaling SQL Database to Basic (Optional - Savings: ~$10/mo)..." -ForegroundColor Yellow
    # az sql db edit --name sqldb-assocmgr-dev-unique --resource-group $ResourceGroup --server sqlsrv-assocmgr-dev-unique --edition Basic --capacity 5
    
    Write-Host "Environment is now in Sleep Mode." -ForegroundColor Green
}
else {
    Write-Host "Waking up environment..." -ForegroundColor Cyan
    foreach ($app in $Apps) {
        Write-Host "Scaling $app to 1 replica..."
        az containerapp update --name $app --resource-group $ResourceGroup --min-replicas 0 --max-replicas 1
    }
    
    Write-Host "Scaling SQL Database back to Standard S0..." -ForegroundColor Yellow
    # az sql db edit --name sqldb-assocmgr-dev-unique --resource-group $ResourceGroup --server sqlsrv-assocmgr-dev-unique --edition Standard --service-objective S0
    
    Write-Host "Environment is Waking Up. First requests might take a few seconds (Cold Start)." -ForegroundColor Green
}
