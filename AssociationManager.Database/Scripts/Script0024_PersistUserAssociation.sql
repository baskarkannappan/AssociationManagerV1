-- Script 0024: Add persistence columns to Users table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AssociationId')
BEGIN
    ALTER TABLE Users ADD AssociationId INT NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'MetadataJson')
BEGIN
    ALTER TABLE Users ADD MetadataJson NVARCHAR(MAX) NULL;
END
GO

-- Update sp_Users_Update to persist AssociationId
CREATE OR ALTER PROCEDURE sp_Users_Update
    @UserId INT,
    @TenantId INT = NULL,
    @GoogleId NVARCHAR(255) = NULL,
    @Email NVARCHAR(255) = NULL,
    @Name NVARCHAR(255),
    @PictureUrl NVARCHAR(MAX) = NULL,
    @Role NVARCHAR(50),
    @CreatedDate DATETIME = NULL,
    @LastLoginDate DATETIME = NULL,
    @IsActive BIT,
    @MetadataJson NVARCHAR(MAX) = NULL,
    @AssociationId INT = NULL
AS
BEGIN
    UPDATE Users 
    SET Name = @Name, 
        PictureUrl = @PictureUrl, 
        Role = @Role, 
        LastLoginDate = @LastLoginDate, 
        IsActive = @IsActive,
        AssociationId = @AssociationId,
        MetadataJson = @MetadataJson
    WHERE UserId = @UserId;
END
GO
