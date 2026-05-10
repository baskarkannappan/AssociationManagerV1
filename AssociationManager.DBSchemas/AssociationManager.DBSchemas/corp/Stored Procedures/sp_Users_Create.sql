-- 3. corp.sp_Users_Create
CREATE   PROCEDURE corp.sp_Users_Create 
    @TenantId INT, 
    @GoogleId NVARCHAR(255) = NULL, 
    @SubjectId NVARCHAR(255) = NULL,
    @Email NVARCHAR(255), 
    @Name NVARCHAR(255), 
    @PictureUrl NVARCHAR(MAX), 
    @Role NVARCHAR(50), 
    @CreatedDate DATETIME, 
    @LastLoginDate DATETIME = NULL, 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO corp.Users (TenantId, GoogleId, SubjectId, Email, Name, PictureUrl, Role, CreatedDate, LastLoginDate, IsActive) 
    VALUES (@TenantId, @GoogleId, @SubjectId, @Email, @Name, @PictureUrl, @Role, @CreatedDate, @LastLoginDate, @IsActive); 

    SELECT SCOPE_IDENTITY();
END