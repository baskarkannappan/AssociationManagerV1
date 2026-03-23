-- 2. Update Procedures
CREATE   PROCEDURE corp.sp_Users_Create 
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