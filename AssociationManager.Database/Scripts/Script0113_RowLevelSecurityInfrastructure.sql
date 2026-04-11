-- Script0113_RowLevelSecurityInfrastructure.sql
-- Implements Row-Level Security (RLS) for automated multi-tenant isolation.

-- 1. Create Security Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Security')
BEGIN
    EXEC('CREATE SCHEMA [Security]')
END
GO

-- 2. Create Tenant Access Predicate Function
-- This function determines if a user can see a row based on SESSION_CONTEXT.
-- It allows bypass for System Administrators (IsAdmin = 1).
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

-- 3. Apply Security Policies to Target Tables
-- We use FILTER PREDICATE for read isolation and BLOCK PREDICATE for write isolation.

-- Policy for corp.Associations
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Associations')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Associations;
GO
CREATE SECURITY POLICY Security.TenantSecurityPolicy_Associations
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[Associations],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[Associations]
    WITH (STATE = ON);
GO

-- Policy for corp.AuditLogs
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_AuditLogs')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_AuditLogs;
GO
CREATE SECURITY POLICY Security.TenantSecurityPolicy_AuditLogs
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[AuditLogs],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [corp].[AuditLogs]
    WITH (STATE = ON);
GO

-- Policy for assoc.Invoices
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Invoices')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Invoices;
GO
CREATE SECURITY POLICY Security.TenantSecurityPolicy_Invoices
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Invoices],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Invoices]
    WITH (STATE = ON);
GO

-- Policy for assoc.Assets
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Assets')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Assets;
GO
CREATE SECURITY POLICY Security.TenantSecurityPolicy_Assets
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Assets],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Assets]
    WITH (STATE = ON);
GO

-- Policy for assoc.Persons
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Persons')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Persons;
GO
CREATE SECURITY POLICY Security.TenantSecurityPolicy_Persons
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Persons],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Persons]
    WITH (STATE = ON);
GO

-- Policy for assoc.Occupancy
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy_Occupancy')
    DROP SECURITY POLICY Security.TenantSecurityPolicy_Occupancy;
GO
CREATE SECURITY POLICY Security.TenantSecurityPolicy_Occupancy
    ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Occupancy],
    ADD BLOCK PREDICATE Security.fn_TenantAccessPredicate(TenantId) ON [assoc].[Occupancy]
    WITH (STATE = ON);
GO
