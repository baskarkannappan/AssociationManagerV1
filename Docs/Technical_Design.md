# Technical Design and High-Level Design (HLD) - AssociationManagerSaaS

## Overview
AssociationManagerSaaS is a multi-tenant platform designed for modularity, scalability, and security. It follows a microservices-lite architecture with a clear separation of concerns across multiple .NET projects.

## Architecture Layers

### 1. Presentation Layer (Blazor WebAssembly)
- **Standalone Blazor WASM**: No ASP.NET Core hosting for the client, making it easier to deploy to CDN/Static sites.
- **Components**: Atomic and reusable UI components using premium CSS variables.
- **Client Services**: Handle communication with the API via `HttpClient`.

### 2. Gateway Layer (YARP Reverse Proxy)
- **Role**: Entry point for all client requests.
- **Routing**: Routes traffic to `AssociationManager.Api` or `AssociationManager.Realtime`.
- **Potential for expansion**: Can easily handle rate limiting, SSL termination, and horizontal scaling.

### 3. Application API Layer
- **RESTful Controllers**: Expose business functionality.
- **Middleware**: Includes `TenantMiddleware` for multi-tenancy and `SecurityHeadersMiddleware`.
- **Serilog Integration**: Structured logging for observability.

### 4. Service Layer
- **Stateless Services**: Implement business logic.
- **Redis Integration**: Uses `IDistributedCache` for performance optimization.
- **Multi-tenant Core**: Services rely on `ITenantAccessor` to maintain tenant context.

### 5. Repository Layer (Dapper)
- **Micro-ORM**: Lightweight data access using Dapper for maximum performance.
- **SQL Templates**: Raw SQL with parameterization to prevent SQL injection.

### 6. Background Processing (Hangfire)
- **Job Orchestration**: Manages long-running tasks asynchronously.
- **SQL Backed**: Persists job state in SQL Server for reliability.

## Data Isolation Strategy
- **Shared Database, Shared Schema**: All tables include a `TenantId`.
- **Discriminator Enforcement**: All repository queries include `WHERE TenantId = @TenantId`.

## Scalability
- **Redis Backplane**: Ensures SignalR messages reach clients connected to different server instances.
- **Distributed Cache**: Shared session and token data across multiple API nodes.
