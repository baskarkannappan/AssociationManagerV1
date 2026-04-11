CREATE SECURITY POLICY Security.TenantSecurityPolicy_Associations
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[Associations],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[Associations]
    WITH (STATE = ON);
GO

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

CREATE SECURITY POLICY Security.TenantSecurityPolicy_Assets
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Assets],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Assets]
    WITH (STATE = ON);
GO

CREATE SECURITY POLICY Security.TenantSecurityPolicy_People
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[People],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[People]
    WITH (STATE = ON);
GO
