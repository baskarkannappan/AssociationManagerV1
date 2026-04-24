# Azure AssociationManager Management

## 🌙 Sleep Mode (Stop Billing)
Run this command to scale all apps to 0:
```powershell
$RG = "rg-assocmgr-dev"
az containerapp update --name assocmgr-dev-gateway --resource-group $RG --min-replicas 0 --max-replicas 1
az containerapp update --name assocmgr-dev-api --resource-group $RG --min-replicas 0 --max-replicas 1
az containerapp update --name assocmgr-dev-corp-api --resource-group $RG --min-replicas 0 --max-replicas 1
az containerapp update --name assocmgr-dev-worker --resource-group $RG --min-replicas 0 --max-replicas 1
```

## ☀️ Wake Up Mode (Resume Apps)
Run this command to bring the apps back online:
```powershell
$RG = "rg-assocmgr-dev"
az containerapp update --name assocmgr-dev-gateway --resource-group $RG --min-replicas 1 --max-replicas 10
az containerapp update --name assocmgr-dev-api --resource-group $RG --min-replicas 1 --max-replicas 10
az containerapp update --name assocmgr-dev-corp-api --resource-group $RG --min-replicas 1 --max-replicas 10
az containerapp update --name assocmgr-dev-worker --resource-group $RG --min-replicas 1 --max-replicas 10
```

## 🔑 Key Vault Reminder
Make sure these secrets are in `kv-assocmgr-dev-unique`:
- `ConnectionStrings--DefaultConnection`
- `AllowedOrigins`
- `JWT--Secret`
- `JWT--Issuer`: `AssocMgr`
- `JWT--Audience`: `AssocMgr`
