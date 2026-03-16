# Deployment Guide - AssociationManagerSaaS

This guide outlines the steps required to deploy the AssociationManagerSaaS platform to production environments.

## Infrastructure Requirements
- **Web App Hosting**: Azure App Service, AWS Elastic Beanstalk, or Kubernetes.
- **Database**: Azure SQL, AWS RDS, or managed SQL Server.
- **Redis**: Azure Cache for Redis, AWS ElastiCache, or managed Redis.
- **Static Hosting**: Azure Static Web Apps, AWS S3/CloudFront, or Cloudflare Pages (for the Blazor WASM client).

## 1. Database Deployment
1. **Provision SQL Server**: Create a new database instance.
2. **Run Migrations**: Deploy and run the `AssociationManager.Database` executable against the production connection string.
   ```bash
   ./AssociationManager.Database --ConnectionStrings:DefaultConnection="your_connection_string"
   ```
3. **User Access**: Ensure the application user has `db_datareader`, `db_datawriter`, and `db_ddladmin` (for Hangfire) permissions.

## 2. Shared Infrastructure
1. **Provision Redis**: Ensure the instance is accessible from the API and Worker roles.
2. **Key Vault / Secrets**: Store production secrets (Connection Strings, JWT Keys, Google Client Secrets) in a secure vault.

## 3. Backend Deployment (Api, Gateway, Worker)
1. **Publish Projects**:
   ```bash
   dotnet publish AssociationManager.Gateway -c Release -o ./publish/gateway
   dotnet publish AssociationManager.Api -c Release -o ./publish/api
   dotnet publish AssociationManager.Worker -c Release -o ./publish/worker
   ```
2. **Environment Variables**: Set the following environment variables in your hosting provider:
   - `ConnectionStrings__DefaultConnection`
   - `Redis__Configuration`
   - `JwtSettings__Key`
   - `GoogleSettings__ClientId`
3. **Reverse Proxy Configuration**: In production, ensure the `AssociationManager.Gateway` (YARP) is configured to point to the internal URIs of the API services.

## 4. Frontend Deployment (Client)
1. **Publish Client**:
   ```bash
   dotnet publish AssociationManager.Client -c Release -o ./publish/client
   ```
2. **Static Site Hosting**: Upload the contents of `./publish/client/wwwroot` to your static hosting provider.
3. **SPA Routing**: Configure your host to serve `index.html` for all 404 routes (required for Blazor routing).

## 5. Post-Deployment Checklist
- [ ] Verify SSL/TLS certificates and HTTPS redirection.
- [ ] Test the Google Login flow with production callback URLs.
- [ ] Check Serilog sinks to ensure logs are flowing to your centralized logging provider (e.g., Azure Monitor, Seq, or ELK).
- [ ] Monitor Hangfire dashboard for successful job initialization.
- [ ] Verify SignalR connectivity via the Gateway.

## 6. Scaling Consideration
- **Horizontal Scaling**: All services are stateless and can be scaled horizontally.
- **Redis Core**: Redis is critical for SignalR and Token rotation; ensure it has high availability (HA).
