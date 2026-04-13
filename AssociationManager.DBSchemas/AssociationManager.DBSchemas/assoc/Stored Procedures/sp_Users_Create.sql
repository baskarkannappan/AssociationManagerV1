CREATE OR ALTER PROCEDURE assoc.sp_Users_Create @TenantId INT = NULL, @GoogleId NVARCHAR(255) = NULL, @Email NVARCHAR(255), @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX) = NULL, @Role NVARCHAR(50) = 'User', @CreatedDate DATETIME, @LastLoginDate DATETIME = NULL, @IsActive BIT = 1 AS 
BEGIN 
    INSERT INTO assoc.Users (TenantId, GoogleId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) 
    OUTPUT INSERTED.UserId 
    VALUES (@TenantId, @GoogleId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive); 
END