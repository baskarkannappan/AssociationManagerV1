CREATE SECURITY POLICY Security.TenantSecurityPolicy_AuditLogs
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[AuditLogs],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[AuditLogs]
    WITH (STATE = ON);
GO

CREATE SECURITY POLICY Security.TenantSecurityPolicy_Invoices
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Invoices],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Invoices]
    WITH (STATE = ON);
GO

CREATE SECURITY POLICY Security.TenantSecurityPolicy_Transactions
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Transactions],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Transactions]
    WITH (STATE = ON);
GO
