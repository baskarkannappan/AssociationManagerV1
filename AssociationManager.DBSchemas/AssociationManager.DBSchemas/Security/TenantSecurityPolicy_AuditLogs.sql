CREATE SECURITY POLICY [Security].[TenantSecurityPolicy_AuditLogs]
    ADD FILTER PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [corp].[AuditLogs],
    ADD BLOCK PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [corp].[AuditLogs]
    WITH (STATE = ON);

