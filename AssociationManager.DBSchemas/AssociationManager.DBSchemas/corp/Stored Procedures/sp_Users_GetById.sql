
-- USERS & ROLES
CREATE   PROCEDURE corp.sp_Users_GetById @Id INT AS 
BEGIN SELECT * FROM corp.Users WHERE UserId = @Id; END