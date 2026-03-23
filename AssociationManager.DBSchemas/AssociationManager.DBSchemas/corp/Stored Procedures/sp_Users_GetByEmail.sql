CREATE   PROCEDURE corp.sp_Users_GetByEmail @Email NVARCHAR(255) AS 
BEGIN SELECT * FROM corp.Users WHERE Email = @Email; END