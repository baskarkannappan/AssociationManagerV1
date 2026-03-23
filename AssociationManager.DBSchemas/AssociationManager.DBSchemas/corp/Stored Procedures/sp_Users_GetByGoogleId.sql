CREATE   PROCEDURE corp.sp_Users_GetByGoogleId @GoogleId NVARCHAR(255) AS 
BEGIN SELECT * FROM corp.Users WHERE GoogleId = @GoogleId; END