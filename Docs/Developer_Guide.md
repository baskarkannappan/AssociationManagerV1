# Developer Guide - AssociationManagerSaaS

This guide provides instructions for setting up the development environment, project structure, and coding standards.

## Prerequisites
- **.NET 9 SDK**
- **SQL Server** (LocalDB or Express)
- **Redis** (Running on port 6379)
    - *Option A (Docker)*: `docker run -d --name redis -p 6379:6379 redis`
    - *Option B (Windows)*: Download and run [Memurai](https://www.memurai.com/get-memurai) or [Redis-Windows](https://github.com/microsoftarchive/redis/releases).
- **Visual Studio 2022** (v17.12+) or **VS Code** with C# Dev Kit.
- **Google OAuth Client ID** (from Google Cloud Console).

## 1. Project Structure
The solution is organized into 9 projects:
- **`AssociationManager.Client`**: Blazor WebAssembly Standalone. (Frontend)
- **`AssociationManager.Api`**: ASP.NET Core Web API. (Main Entry)
- **`AssociationManager.Gateway`**: YARP Reverse Proxy. (Public Entry)
- **`AssociationManager.Auth`**: Business logic for JWT and Google Auth.
- **`AssociationManager.Services`**: Core business services with Redis caching.
- **`AssociationManager.Data`**: Dapper-based repository layer.
- **`AssociationManager.Shared`**: Common DTOs, Enums, and Models.
- **`AssociationManager.Worker`**: Hangfire background job processor.
- **`AssociationManager.Realtime`**: SignalR Hubs and messaging services.

## 2. Local Setup
1. **Clone the repository**.
2. **Database Setup**:
   - Run the `AssociationManager.Database` project to automatically create the database and apply the schema.
   ```bash
   dotnet run --project AssociationManager.Database
   ```
3. **Configuration (Local Development)**:
   - To work locally without Azure Key Vault, edit the `localappsettings.json` file in the root directory with your local credentials.
   - Run the setup script to distribute these settings to all projects:
   ```powershell
   ./apply-local-settings.ps1
   ```
   - This will create `appsettings.Development.json` files for all APIs and update `local.settings.json` for the Azure Functions.
4. **Run the projects**:
   - Run the startup script to launch all services:
   ```powershell
   ./run-all.ps1
   ```
   - Alternatively, using Visual Studio: Set Multiple Startup Projects (Api, Gateway, Worker, Client).

## 3. Coding Standards
- **Asynchronous Everything**: Use `async`/`await` for all I/O bound operations.
- **Dapper Usage**: Use the `DbConnectionFactory` to get a connection. Always use parameterized queries.
- **Multi-tenancy**: Ensure all queries filter by `TenantId`. In the services, use `ITenantAccessor` to get the current tenant.
- **Logging**: Use `ILogger<T>` for structured logging via Serilog.
- **Caching**: Use `IDistributedCache` for frequent lookup data. Invalidate the cache whenever data is modified.

## 4. Troubleshooting
- **Redis Connection**: If the API fails at startup, ensure Redis is running.
- **Auth Errors**: Verify that the JWT Key in `appsettings.json` is at least 32 characters long.
- **CORS Issues**: Ensure the client URL matches the `AllowClient` origin in the API's `Program.cs`.
