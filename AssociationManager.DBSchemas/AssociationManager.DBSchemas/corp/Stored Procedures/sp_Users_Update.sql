CREATE   PROCEDURE corp.sp_Users_Update 
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