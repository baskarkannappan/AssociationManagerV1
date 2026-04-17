CREATE   PROCEDURE assoc.sp_Users_GetByGoogleId @GoogleId NVARCHAR(255) AS 
BEGIN SELECT * FROM assoc.Users WHERE GoogleId = @GoogleId; END