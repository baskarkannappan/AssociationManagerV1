# Production Readiness Checklist

This document tracks the tasks required to transition the Association Manager platform from development/testing to a stable production environment.

## 1. Observability & Monitoring
- [ ] **Application Insights**: Integrate into `Api`, `Corporate.Api`, and `Gateway`.
- [ ] **Health Checks**: Add `/health` endpoints and configure ACA Liveness/Readiness probes.
- [ ] **Alerting**: Configure Azure Monitor alerts for 5xx errors and high database DTU usage.
- [ ] **Log Centralization**: Ensure all application logs are streaming to a Log Analytics Workspace.

## 2. Infrastructure & Scaling
- [ ] **VNet Integration**: Restrict SQL Server and Redis access to the VNet used by Container Apps.
- [ ] **Scaling Rules**: Define autoscale rules (e.g., scale out on >70% CPU).
- [ ] **Custom Domains**: Bind production domains and verify SSL/TLS certificates.
- [ ] **Geo-Redundancy**: Verify SQL Database backup/restore and consider a failover group.

## 3. Security
- [ ] **WAF Integration**: Place Azure Front Door or App Gateway with WAF in front of the Gateway.
- [ ] **Security Headers**: Implement CSP, HSTS, and X-Content-Type-Options in the Gateway.
- [ ] **Secrets Rotation**: Set up a process for periodic rotation of JWT keys and DB passwords.
- [ ] **Managed Identity**: Ensure all ACA-to-SQL and ACA-to-KeyVault connections use System-Assigned Identities.

## 4. Application Services
- [ ] **Production Email**: Migrate from Gmail SMTP to **Azure Communication Services (ACS)** or SendGrid.
- [ ] **Email Authentication**: Configure SPF, DKIM, and DMARC for the sender domain.
- [ ] **Redis Tier**: Upgrade Redis to "Standard" tier for SLA and data persistence.
- [ ] **CDN**: Enable CDN for static assets (Blazor WASM files) to improve global performance.

## 5. Compliance & Operations
- [ ] **Database Migrations**: Test the schema migration process against a production-sized data set.
- [ ] **Backup Verification**: Perform a test restore of the database to verify backup integrity.
- [ ] **Cost Management**: Set up Azure budgets and tags for cost tracking per environment.
- [ ] **PII Review**: Ensure no Personally Identifiable Information (PII) is being logged to App Insights.

---
*Note: This list is a living document. Add environment-specific items as discovered during UAT.*
