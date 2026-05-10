CREATE   PROCEDURE corp.sp_Users_Update 
    @UserId INT, 
    @GoogleId NVARCHAR(255) = NULL,
    @SubjectId NVARCHAR(255) = NULL,
    @Name NVARCHAR(255), 
    @PictureUrl NVARCHAR(MAX), 
    @Role NVARCHAR(50), 
    @LastLoginDate DATETIME, 
    @IsActive BIT 
AS 
BEGIN 
    UPDATE corp.Users 
    SET 
        GoogleId = COALESCE(@GoogleId, GoogleId),
        SubjectId = COALESCE(@SubjectId, SubjectId),
        Name = @Name, 
        PictureUrl = @PictureUrl, 
        Role = @Role, 
        LastLoginDate = @LastLoginDate, 
        IsActive = @IsActive 
    WHERE UserId = @UserId; 
END