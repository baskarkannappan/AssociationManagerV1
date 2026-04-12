CREATE SECURITY POLICY [Security].[TenantSecurityPolicy_Transactions]
    ADD FILTER PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Transactions],
    ADD BLOCK PREDICATE [Security].[fn_TenantAccessPredicate]([TenantId]) ON [assoc].[Transactions]
    WITH (STATE = ON);

