-- Script0087_UpdateAssociationProcedures.sql
-- Updating Association CRUD stored procedures to include new Platform Billing fields

CREATE OR ALTER PROCEDURE corp.sp_Associations_Create 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX), 
    @CreatedDate DATETIME, 
    @CreatedBy INT,
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1
AS 
BEGIN 
    INSERT INTO corp.Associations (TenantId, Name, Description, CreatedDate, CreatedBy, PlatformAccountId, AdminPaysFee) 
    OUTPUT INSERTED.AssociationId 
    VALUES (@TenantId, @Name, @Description, @CreatedDate, @CreatedBy, @PlatformAccountId, @AdminPaysFee); 
END
GO

CREATE OR ALTER PROCEDURE corp.sp_Associations_Update 
    @AssociationId INT, 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX),
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1
AS 
BEGIN 
    UPDATE corp.Associations 
    SET Name = @Name, 
        Description = @Description,
        PlatformAccountId = @PlatformAccountId,
        AdminPaysFee = @AdminPaysFee
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId; 
END
GO
