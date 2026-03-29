-- User Management Stored Procedures

-- 1. Get All Users (Schema-aware)
CREATE   PROCEDURE corp.sp_Users_List
AS
BEGIN
    SELECT * FROM corp.Users ORDER BY Name;
END;