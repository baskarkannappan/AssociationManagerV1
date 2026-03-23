CREATE   PROCEDURE assoc.sp_Users_Update @UserId INT, @Name NVARCHAR(255), @PictureUrl NVARCHAR(MAX), @Role NVARCHAR(50), @LastLoginDate DATETIME, @IsActive BIT AS 
BEGIN 
    UPDATE assoc.Users SET Name = @Name, PictureUrl = @PictureUrl, Role = @Role, LastLoginDate = @LastLoginDate, IsActive = @IsActive 
    WHERE UserId = @UserId; 
END