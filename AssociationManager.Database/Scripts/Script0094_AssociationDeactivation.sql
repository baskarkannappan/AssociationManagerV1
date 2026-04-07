-- 1. Add Status and AdminEmail columns to Associations table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.Associations') AND name = 'Status')
BEGIN
    ALTER TABLE corp.Associations ADD Status NVARCHAR(50) NOT NULL DEFAULT 'Active';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.Associations') AND name = 'AdminEmail')
BEGIN
    ALTER TABLE corp.Associations ADD AdminEmail NVARCHAR(255) NULL;
END
GO

-- 2. Update sp_Associations_GetById
CREATE OR ALTER PROCEDURE corp.sp_Associations_GetById @Id INT, @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE AssociationId = @Id AND TenantId = @TenantId; END
GO

-- 3. Update sp_Associations_GetAllByTenantId
CREATE OR ALTER PROCEDURE corp.sp_Associations_GetAllByTenantId @TenantId INT AS 
BEGIN SELECT * FROM corp.Associations WHERE TenantId = @TenantId; END
GO

-- 4. Update sp_Associations_Create
CREATE OR ALTER PROCEDURE corp.sp_Associations_Create 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX), 
    @CreatedDate DATETIME, 
    @CreatedBy INT,
    @AdminEmail NVARCHAR(255) = NULL,
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1
AS 
BEGIN 
    INSERT INTO corp.Associations (TenantId, Name, Description, CreatedDate, CreatedBy, AdminEmail, PlatformAccountId, AdminPaysFee, Status) 
    OUTPUT INSERTED.AssociationId 
    VALUES (@TenantId, @Name, @Description, @CreatedDate, @CreatedBy, @AdminEmail, @PlatformAccountId, @AdminPaysFee, 'Active'); 
END
GO

-- 5. Update sp_Associations_Update
CREATE OR ALTER PROCEDURE corp.sp_Associations_Update 
    @AssociationId INT, 
    @TenantId INT, 
    @Name NVARCHAR(255), 
    @Description NVARCHAR(MAX),
    @AdminEmail NVARCHAR(255) = NULL,
    @PlatformAccountId INT = NULL,
    @AdminPaysFee BIT = 1,
    @Status NVARCHAR(50) = 'Active'
AS 
BEGIN 
    UPDATE corp.Associations 
    SET Name = @Name, 
        Description = @Description,
        AdminEmail = ISNULL(@AdminEmail, AdminEmail),
        PlatformAccountId = @PlatformAccountId,
        AdminPaysFee = @AdminPaysFee,
        Status = @Status
    WHERE AssociationId = @AssociationId AND TenantId = @TenantId; 
END
GO

-- 6. Update sp_Associations_Delete to Deactivate instead
CREATE OR ALTER PROCEDURE corp.sp_Associations_Delete @Id INT, @TenantId INT AS 
BEGIN 
    UPDATE corp.Associations SET Status = 'Deactivated' WHERE AssociationId = @Id AND TenantId = @TenantId; 
END
GO

-- 7. Add sp_Associations_UpdateStatus
CREATE OR ALTER PROCEDURE corp.sp_Associations_UpdateStatus @Id INT, @Status NVARCHAR(50) AS 
BEGIN 
    UPDATE corp.Associations SET Status = @Status WHERE AssociationId = @Id; 
END
GO

-- 8. Update sp_AssociationProfile_Get to include status from corp.Associations
CREATE OR ALTER PROCEDURE assoc.sp_AssociationProfile_Get
    @AssociationId INT
AS
BEGIN
    SELECT p.*, a.Status
    FROM assoc.AssociationProfile p
    JOIN corp.Associations a ON p.AssociationId = a.AssociationId
    WHERE p.AssociationId = @AssociationId;
END;
GO

-- 9. Update sp_Associations_GetByUserId to include status
CREATE OR ALTER PROCEDURE corp.sp_Associations_GetByUserId @UserId INT AS 
BEGIN
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN corp.UserAssociations ua ON a.TenantId = ua.TenantId
    WHERE ua.UserId = @UserId AND ua.Role IN ('SystemAdmin', 'AssociationAdmin', 'PlatformAdmin')
    UNION
    SELECT DISTINCT a.* FROM corp.Associations a
    INNER JOIN assoc.Occupancy o ON a.AssociationId = o.AssociationId
    INNER JOIN assoc.Persons p ON o.PersonId = p.PersonId
    INNER JOIN corp.Users u ON p.Email = u.Email
    WHERE u.UserId = @UserId
END
GO
