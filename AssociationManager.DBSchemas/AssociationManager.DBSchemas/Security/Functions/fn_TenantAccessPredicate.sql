CREATE FUNCTION Security.fn_TenantAccessPredicate(@TenantId INT)
    RETURNS TABLE
    WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_access_result
    WHERE 
        (CAST(SESSION_CONTEXT(N'TenantId') AS INT) = @TenantId)
        OR (CAST(SESSION_CONTEXT(N'IsAdmin') AS INT) = 1);
GO
