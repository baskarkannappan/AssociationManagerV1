Since we used Serverless and Pay-as-you-go resources, your costs will be extremely low (near zero) when you aren't using the app. Here is the breakdown of how to "pause" and what will happen:

1. Azure SQL Database (Automatic)
Your database is configured with Auto-pause (set to 60 minutes). It will automatically shut down and stop charging you for compute after 1 hour of inactivity. It will wake up automatically when you try to connect again later.

2. Container Apps (Manual Scale to 0)
The most active part of your bill would be the Container Apps. You can "pause" them by scaling them to zero replicas with this command:

powershell
$apps = az containerapp list --resource-group rg-assocmgr-dev --query "[].name" -o tsv
foreach ($app in $apps) {
    az containerapp revision label add --name $app --resource-group rg-assocmgr-dev --label "paused" --no-wait
    az containerapp up --name $app --resource-group rg-assocmgr-dev --min-replicas 0 --max-replicas 0
}
3. Static Web Apps & Key Vault
Static Web Apps: You are on the Free Tier, so there is no charge.
Key Vault & Registry: These have a very tiny storage fee (usually less than $1 per month) and cannot be "paused," but the cost is negligible.
When you come back:
To "unpause" your Container Apps, just run this to allow them to scale up again:

powershell
foreach ($app in $apps) {
    az containerapp up --name $app --resource-group rg-assocmgr-dev --min-replicas 1 --max-replicas 3
}


azure sql database details
Server=assocmgr-dev-sql-srv-enhlyslcz7cne.database.windows.net;Initial Catalog=assocmgr-dev-db;Persist Security Info=False;User ID=appadmin;Password=AssocMgr@2026!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;



Type	Name	Value Source
Secret	SWA_TOKEN_CLIENT	Azure Portal (Static Web App -> Manage deployment token)
Secret	SWA_TOKEN_CORPORATE_CLIENT	Azure Portal (Static Web App -> Manage deployment token)
Secret	SQL_CONNECTION_STRING	Use the string you just saved in your Docs/start_stop.md
Secret	SQL_ADMIN_PASSWORD	AssocMgr@2026! (from your file)
Variable	ACR_NAME	assocmgrdevacrenhlyslcz7cne
Variable	AZURE_RESOURCE_GROUP	rg-assocmgr-dev



---------sql connect
az sql server firewall-rule create --resource-group rg-assocmgr-dev --server assocmgr-dev-sql-srv-enhlyslcz7cne --name AllowMyLocalIP --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255
