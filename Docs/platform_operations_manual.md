# AssociationManager - Platform Operations Manual

Welcome to the **AssociationManager** Founder's Playbook. This manual provides everything you need to develop, deploy, and maintain your startup platform across local and cloud environments.

---

## 1. Local Development (The Inner Loop)

### Prerequisites
- **.NET 9.0 SDK**: The core runtime.
- **SQL Server LocalDB**: For the local persistent store.
- **Docker Desktop**: Required for building and testing cloud containers locally.

### One-Click Launch
The entire platform (6 services) can be started using the main PowerShell script:
```powershell
./run-all.ps1
```
This script will:
1. Kill any stale .NET processes.
2. Build all 14 projects.
3. Run database migrations.
4. Start the Gateway (7000), APIs (5001/7010), and Clients (7001/7011).

### Troubleshooting Local Startup
- **"Port already in use"**: The script automatically stops existing processes, but if a port is stuck, use `Stop-Process -Name "dotnet" -Force`.
- **Database Migrations**: If you change the database schema, the `AssociationManager.Database` project handles the update automatically during the `run-all` sequence.

---

## 2. Azure Cloud Architecture (The Scale Loop)

We use a **Consumption-Based Architecture** to keep costs near zero during your startup phase.

### Components
- **Azure Container Apps (ACA)**: Hosts your APIs. They are set to `Min Replicas: 0`, meaning you pay **$0** when no one is using the site.
- **Azure Static Web Apps (SWA)**: Hosts your Blazor frontends. It's on the **Free Tier**, providing global speed at no cost.
- **Azure SQL Serverless**: Databases that "auto-pause" after 1 hour of inactivity to save costs.

---

## 3. DevOps & CI/CD (GitHub Actions)

Your "Strong DevOps" setup consists of two main pipelines in the `.github/workflows` folder.

### Infrastructure (`azure-infra.yml`)
- **Purpose**: Creates the Azure resources (SQL, Vault, Registry).
- **When to run**: Whenever you change a Bicep file or need to set up a new environment (e.g., Prod).
- **Control**: Can be triggered manually from the GitHub "Actions" tab.

### Application (`azure-deploy.yml`)
- **Purpose**: Builds images, pushes to registry, and updates the live apps.
- **When to run**: Automatically triggers whenever you push code to the `develop` branch.
- **Scope**: Deploys all 4 backend services and 2 frontend clients in parallel.

---

## 4. Security & Secret Management

**NEVER** put passwords or secrets in your code.

### Azure Key Vault
All production secrets (Database passwords, Google OAuth keys) live in **Azure Key Vault**. 
- Your APIs use **Managed Identity** to talk to the Vault—they don't need a password to access the password!

### GitHub Secrets
To link GitHub to Azure, you must set these secrets:
- `AZURE_CREDENTIALS`: The secret handshake for Azure.
- `SWA_TOKEN_Client`: The key for the Association UI.
- `SWA_TOKEN_Corporate.Client`: The key for the Corporate UI.

---

## 5. Scaling to Production

When you are ready to launch **Production**:
1. Create a new branch called `main`.
2. Update the `azure-infra.yml` to target a new Resource Group (e.g., `assocmgr-prod-rg`).
3. Run the Infrastructure pipeline once.
4. Your cost will remain low because the "Serverless" logic scales based on your user growth.

---

## 6. Common Issues & Resolution

| Issue | Cause | Fix |
| :--- | :--- | :--- |
| **502 Bad Gateway** | API is crashing on startup or taking too long. | Check the API Logs in Azure Portal. Usually a DI mismatch or missing secret. |
| **Connection Refused** | The service process is not running. | Verify the Container App status in Azure. Ensure `Min Replicas` is reached. |
| **Mobile Auth Fail** | Mismatched Google ClientID. | Ensure the ClientID in the Mobile App matches the one in the Backend `appsettings.json`. |

---

## 7. Manual Azure Configuration (Portal Override)

If you need to create these components manually in the [Azure Portal](https://portal.azure.com), follow these blueprints:

### A. Azure SQL Serverless (Database)
1. **Create SQL Database**: Set the tier to **General Purpose**.
2. **Compute Tier**: Select **Serverless**.
3. **Auto-Pause**: Set "Auto-pause delay" to **1 hour**. This is the key to your cost savings!
4. **Networking**: Ensure "Allow Azure services to access this server" is checked.

### B. Azure Key Vault (Secrets)
1. **Access Configuration**: Use **Azure Role-Based Access Control (RBAC)**.
2. **Secrets**: Add your secrets using these exact names:
   - `ConnectionStrings--DefaultConnection` (Use `--` for levels)
   - `GoogleSettings--ClientId`
   - `JwtSettings--Key`

### C. Azure Container Apps (Gateway & APIs)
1. **Create Environment**: Create a single "Container Apps Environment" for all services to share.
2. **Registry**: Go to the **Settings > Container** tab. Link it to your Azure Container Registry (ACR).
3. **Ingress (Networking)**:
   - **Gateway**: Enable Ingress, set to **External**, Port **8080**.
   - **APIs**: Enable Ingress, set to **Internal** (if you only want traffic via Gateway) or **External** for testing.

> [!IMPORTANT]
> **Always monitor your Azure Costs**: Check the "Cost Analysis" tab in the Azure Portal once a week to ensure your serverless services are pausing as expected.

---
*End of Manual*
