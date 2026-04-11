-- Script0114_SecurityEmergencyFix.sql
-- MANDATORY FIX: Force-drops restrictive Row-Level Security policies that are blocking the login/selection flow.
-- This script is necessary because DbUp skipped updates to Script0113.

-- 1. FORCE DROP ALL POTENTIALLY BLOCKING POLICIES
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Associations')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Associations;
GO
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Persons')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Persons;
GO
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Occupancy')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Occupancy;
GO
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Assets')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Assets;
GO
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_AuditLogs')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_AuditLogs;
GO
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Invoices')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Invoices;
GO
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Transactions')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Transactions;
GO

-- 2. RE-ESTABLISH SECURE ACCESS PREDICATE
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('Security.fn_TenantAccessPredicate') AND type in (N'IF', N'FN', N'TF'))
BEGIN
    DROP FUNCTION Security.fn_TenantAccessPredicate;
END
GO

CREATE FUNCTION Security.fn_TenantAccessPredicate(@TenantId INT)
    RETURNS TABLE
    WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS fn_access_result
    WHERE 
        (CAST(SESSION_CONTEXT(N'TenantId') AS INT) = @TenantId)
        OR (CAST(SESSION_CONTEXT(N'IsAdmin') AS INT) = 1);
GO

-- 3. APPLY ISOLATION ONLY TO TRANSACTIONAL DATA
-- We protect money and history, but keep the 'Discovery' path open for login.

-- Policy for corp.AuditLogs
CREATE SECURITY POLICY Security.TenantSecurityPolicy_AuditLogs
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[AuditLogs],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[AuditLogs]
    WITH (STATE = ON);
GO

-- Policy for assoc.Invoices
CREATE SECURITY POLICY Security.TenantSecurityPolicy_Invoices
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Invoices],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Invoices]
    WITH (STATE = ON);
GO

-- Policy for assoc.Transactions
CREATE SECURITY POLICY Security.TenantSecurityPolicy_Transactions
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Transactions],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Transactions]
    WITH (STATE = ON);
GO
