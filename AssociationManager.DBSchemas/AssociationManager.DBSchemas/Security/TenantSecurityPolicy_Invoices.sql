CREATE SECURITY POLICY [Security].[TenantSecurityPolicy_Invoices]
    ADD FILTER PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Invoices],
    ADD BLOCK PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Invoices]
    WITH (STATE = ON);

