-- Script0088_NullableAuditLogAssociation.sql
-- Making AssociationId nullable in AuditLogs for Global/Corporate actions

-- 1. Drop the foreign key constraint
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AuditLogs_Associations' AND parent_object_id = OBJECT_ID('corp.AuditLogs'))
BEGIN
    ALTER TABLE [corp].[AuditLogs] DROP CONSTRAINT [FK_AuditLogs_Associations];
END
GO

-- 2. Make AssociationId Nullable
ALTER TABLE [corp].[AuditLogs] ALTER COLUMN [AssociationId] INT NULL;
GO

-- 3. Add the foreign key back (Allowing NULLs)
ALTER TABLE [corp].[AuditLogs] WITH CHECK ADD CONSTRAINT [FK_AuditLogs_Associations] 
FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]);
GO

-- 4. Update sp_AuditLogs_Create to handle NULL AssociationId
CREATE OR ALTER PROCEDURE corp.sp_AuditLogs_Create
    @TenantId INT,
    @AssociationId INT = NULL,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @Action NVARCHAR(MAX),
    @Entity NVARCHAR(100) = NULL,
    @EntityId INT = NULL,
    @IpAddress NVARCHAR(50) = NULL,
    @Timestamp DATETIME
AS
BEGIN
    INSERT INTO corp.AuditLogs (TenantId, AssociationId, UserId, AssetId, Action, Entity, EntityId, IpAddress, Timestamp)
    VALUES (@TenantId, @AssociationId, @UserId, @AssetId, @Action, @Entity, @EntityId, @IpAddress, @Timestamp);
    
    SELECT SCOPE_IDENTITY();
END
GO
