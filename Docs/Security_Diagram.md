# Security Diagram - AssociationManagerSaaS

```mermaid
graph TD
    User((User/Browser)) -->|HTTPS/TLS 1.3| CDN[CDN / WAF]
    CDN -->|Filtered Traffic| Gateway[API Gateway / YARP]
    
    subgraph "Trust Boundary: Internal Network"
        Gateway -->|Reverse Proxy| Api[ASP.NET Core API]
        Api -->|Google Token Validation| GoogleSvc[Google Identity Services]
        
        Api -->|JWT Auth & Token Rotation| AuthService[Auth Service]
        AuthService <-->|Refresh Token Storage| Redis[(Redis - Cache & Sessions)]
        
        Api -->|Tenant Isolation Middleware| Services[Business Services]
        Services -->|Parameterized SQL| DB[(SQL Server - Encrypted at Rest)]
        
        Api -->|Serilog| Logs[Audit Logs & Monitoring]
    end

    style logs fill:#f9f,stroke:#333,stroke-width:2px
    style DB fill:#85C1E9,stroke:#333,stroke-width:2px
    style Redis fill:#F1948A,stroke:#333,stroke-width:2px
```

## Security Features
1. **JWT Authentication**: Short-lived access tokens (15m).
2. **Token Rotation**: Refresh tokens expire and rotate on every use.
3. **Multi-tenancy**: Hardcoded `TenantId` discriminator in all SQL queries via Dapper.
4. **Data Protection**: Secrets managed via environment variables/Key Vault (recommended for production).
5. **Real-time Security**: SignalR hubs protected with JWT authorization.
6. **Background Security**: Hangfire jobs run with service account permissions.
