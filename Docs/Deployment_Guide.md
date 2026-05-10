# AssociationManager Azure Deployment Playbook

This document serves as a reference for the successful deployment of the AssociationManager SaaS platform to Azure.

## 🏗️ Architecture Overview
- **Frontend**: Azure Static Web Apps (SWA)
- **Backend**: Azure Container Apps (ACA)
- **Database**: Azure SQL (Serverless)
- **Secrets**: Azure Key Vault
- **Registry**: Azure Container Registry (ACR)

---

## 🚀 Critical Lessons Learned (The "Gotchas")

### 1. The .NET 9 Port Mismatch
**Issue**: .NET 8 and 9 images listen on port **8080** by default, but Azure Container Apps default to port **80**.
**Fix**: Ensure `TargetPort` is set to `8080` in the Ingress settings.
```powershell
az containerapp ingress update --name <app-name> --resource-group <rg> --target-port 8080
```

### 2. Managed Identity & Key Vault
**Issue**: When apps are deleted/re-created via `az containerapp up`, their Managed Identity is lost.
**Fix**: 
1. Enable System-Assigned Identity.
2. Grant "Key Vault Secrets User" role on the Key Vault to the app's Principal ID.
3. Inject `KeyVaultName` as an environment variable to override `appsettings.json`.

### 3. Google OAuth Origins
**Issue**: Login fails with `origin_mismatch`.
**Fix**: Add BOTH the base URL and the callback URL to the Google Cloud Console:
- **Origin**: `https://<app-name>.azurestaticapps.net`
- **Redirect URI**: `https://<app-name>.azurestaticapps.net/authentication/login-callback`

---

## 🛠️ Management Commands

### Start/Stop (Cost Savings)
See [start_stop.md](file:///c:/Users/Baska/source/repos/baskarkannappan/AssociationManagerV1_dev/Docs/start_stop.md) for the exact scripts to scale to zero.

### View Logs
To see why an app is failing:
```powershell
# System logs (Azure events)
az containerapp logs show --name <app-name> --resource-group <rg> --type system

# Application logs (Console.WriteLine)
az containerapp logs show --name <app-name> --resource-group <rg> --tail 100
```

---

## 🔗 Live URLs
| Component | URL |
| :--- | :--- |
| **Association Portal** | [https://happy-tree-0a717950f.7.azurestaticapps.net](https://happy-tree-0a717950f.7.azurestaticapps.net) |
| **Corporate Portal** | [https://lemon-coast-03635380f.7.azurestaticapps.net](https://lemon-coast-03635380f.7.azurestaticapps.net) |
| **API Gateway** | `assocmgr-dev-gateway.yellowmoss-1aeb0444.centralindia.azurecontainerapps.io` |

---

## 🔑 Key Vault Secrets Checklist
Ensure these are in `kv-assocmgr-dev-unique`:
- `ConnectionStrings--DefaultConnection`
- `AllowedOrigins` (Comma-separated frontend URLs)
- `JwtSettings--Key` (32+ chars)
- `JwtSettings--Issuer`
- `JwtSettings--Audience`
- `GoogleSettings--ClientId`
- `Smtp--Host`
- `Smtp--Username`
- `Smtp--Password`
- `Smtp--FromEmail`
- `EmailSettings--AzureStorageConnectionString`
- `EmailSettings--QueueName`
- `Redis--Configuration`
