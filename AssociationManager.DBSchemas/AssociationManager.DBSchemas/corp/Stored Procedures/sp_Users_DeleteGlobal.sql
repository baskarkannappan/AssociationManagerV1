
-- 2. Delete User (Global)
CREATE   PROCEDURE corp.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM corp.UserAssociations WHERE UserId = @UserId;
    DELETE FROM corp.Users WHERE UserId = @UserId;
END;