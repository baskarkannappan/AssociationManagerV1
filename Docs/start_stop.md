# Azure AssociationManager Management

## 🌙 Sleep Mode (Stop Billing)
Run this command to scale all apps to 0:
```powershell
$RG = "rg-assocmgr-dev"
az containerapp update --name assocmgr-dev-gateway --resource-group $RG --min-replicas 0 --max-replicas 1
az containerapp update --name assocmgr-dev-api --resource-group $RG --min-replicas 0 --max-replicas 1
az containerapp update --name assocmgr-dev-corp-api --resource-group $RG --min-replicas 0 --max-replicas 1
```

## ☀️ Wake Up Mode (Resume Apps)
Run this command to bring the apps back online:
```powershell
$RG = "rg-assocmgr-dev"
az containerapp update --name assocmgr-dev-gateway --resource-group $RG --min-replicas 1 --max-replicas 10
az containerapp update --name assocmgr-dev-api --resource-group $RG --min-replicas 1 --max-replicas 10
az containerapp update --name assocmgr-dev-corp-api --resource-group $RG --min-replicas 1 --max-replicas 10
```

## 💻 Local Development Mode
If you are working on your laptop and don't want to connect to Azure Key Vault:

1. **Configure**: Update `localappsettings.json` in the root.
2. **Apply**: Run `./apply-local-settings.ps1`
3. **Run**: Run `./run-all.ps1` (or use Visual Studio)

## 🔑 Key Vault Reminder
Make sure these secrets are in `kv-assocmgr-dev-unique` for cloud deployment:
- `ConnectionStrings--DefaultConnection`
- `AllowedOrigins`
- `JwtSettings--Key`
- `JwtSettings--Issuer`
- `JwtSettings--Audience`
- `Smtp--Password`
- `EmailSettings--AzureStorageConnectionString`
