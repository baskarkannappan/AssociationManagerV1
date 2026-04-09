-- Script0106_AuditLogsGlobalSupport.sql
-- Ensures AuditLogs.AssociationId is nullable to support system-wide background job logging

-- 1. Identify which AuditLogs table we are using
-- (Handles cases where schemas might be slightly different across environments)

DECLARE @SchemaName NVARCHAR(100) = 'corp';
IF EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'assoc' AND t.name = 'AuditLogs')
    SET @SchemaName = 'assoc';

-- 2. Drop the FK if it exists (on either schema)
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AuditLogs_Associations')
    ALTER TABLE [corp].[AuditLogs] DROP CONSTRAINT [FK_AuditLogs_Associations];
GO
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AuditLogs_Associations')
    ALTER TABLE [assoc].[AuditLogs] DROP CONSTRAINT [FK_AuditLogs_Associations];
GO

-- 3. Make AssociationId Nullable (Perform on both to be safe, if they exist)
IF EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'corp' AND t.name = 'AuditLogs')
    ALTER TABLE [corp].[AuditLogs] ALTER COLUMN [AssociationId] INT NULL;
GO
IF EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'assoc' AND t.name = 'AuditLogs')
    ALTER TABLE [assoc].[AuditLogs] ALTER COLUMN [AssociationId] INT NULL;
GO

-- 4. Re-add FK against the correct Associations table
-- Identify where Associations table is
DECLARE @AssocSchema NVARCHAR(100) = 'corp';
IF EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'assoc' AND t.name = 'Associations')
    SET @AssocSchema = 'assoc';

-- Re-apply FK to the primary AuditLogs table (likely corp)
IF EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'corp' AND t.name = 'AuditLogs')
BEGIN
    IF @AssocSchema = 'assoc'
        ALTER TABLE [corp].[AuditLogs] WITH CHECK ADD CONSTRAINT [FK_AuditLogs_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [assoc].[Associations] ([AssociationId]);
    ELSE
        ALTER TABLE [corp].[AuditLogs] WITH CHECK ADD CONSTRAINT [FK_AuditLogs_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]);
END
GO
