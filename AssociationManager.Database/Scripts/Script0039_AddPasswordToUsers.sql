USE AssociationManagerV1;
GO

-- 1. Add PasswordHash column and make GoogleId nullable
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('corp.Users') AND name = 'PasswordHash')
BEGIN
    ALTER TABLE corp.Users ADD PasswordHash NVARCHAR(500) NULL;
END
GO

ALTER TABLE corp.Users ALTER COLUMN GoogleId NVARCHAR(200) NULL;
GO

-- 2. Update Procedures
CREATE OR ALTER PROCEDURE corp.sp_Users_Create 
    @TenantId INT, 
    @GoogleId NVARCHAR(255) = NULL, 
    @Email NVARCHAR(255), 
    @Name NVARCHAR(255), 
    @PictureUrl NVARCHAR(MAX) = NULL, 
    @Role NVARCHAR(50), 
    @CreatedDate DATETIME, 
    @LastLoginDate DATETIME = NULL, 
    @IsActive BIT,
    @PasswordHash NVARCHAR(500) = NULL
AS 
BEGIN 
    INSERT INTO corp.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive, PasswordHash) 
    OUTPUT INSERTED.UserId 
    VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive, @PasswordHash); 
END
GO

CREATE OR ALTER PROCEDURE corp.sp_Users_Update 
    @UserId INT, 
    @Name NVARCHAR(255), 
    @PictureUrl NVARCHAR(MAX), 
    @Role NVARCHAR(50), 
    @LastLoginDate DATETIME, 
    @IsActive BIT,
    @PasswordHash NVARCHAR(500) = NULL
AS 
BEGIN 
    UPDATE corp.Users 
    SET Name = @Name, 
        PictureUrl = @PictureUrl, 
        Role = @Role, 
        LastLoginDate = @LastLoginDate, 
        IsActive = @IsActive,
        PasswordHash = COALESCE(@PasswordHash, PasswordHash)
    WHERE UserId = @UserId; 
END
GO
