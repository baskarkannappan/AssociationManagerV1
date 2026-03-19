/*
    Script 0017: Fix User Procedures
    Update sp_Users_Create and sp_Users_Update to accept all properties of the User model to prevent Dapper parameter mismatch errors.
*/

GO
CREATE OR ALTER PROCEDURE sp_Users_Create
    @TenantId INT,
    @GoogleId NVARCHAR(255) = NULL,
    @Email NVARCHAR(255),
    @Name NVARCHAR(255),
    @PictureUrl NVARCHAR(MAX) = NULL,
    @Role NVARCHAR(50),
    @CreatedDate DATETIME,
    @LastLoginDate DATETIME = NULL,
    @IsActive BIT,
    @MetadataJson NVARCHAR(MAX) = NULL,
    @AssociationId INT = NULL,
    @UserId INT = NULL -- Ignore if passed during create
AS
BEGIN
    INSERT INTO Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive)
    OUTPUT INSERTED.UserId
    VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive);
END
GO

CREATE OR ALTER PROCEDURE sp_Users_Update
    @UserId INT,
    @TenantId INT = NULL, -- Accept but ignore if not needed for update
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
        IsActive = @IsActive 
    WHERE UserId = @UserId;
END
GO
