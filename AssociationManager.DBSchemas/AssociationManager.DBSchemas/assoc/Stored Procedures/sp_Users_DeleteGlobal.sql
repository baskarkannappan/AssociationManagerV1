
CREATE   PROCEDURE assoc.sp_Users_DeleteGlobal
    @UserId INT
AS
BEGIN
    DELETE FROM assoc.UserAssociations WHERE UserId = @UserId;
    DELETE FROM assoc.Users WHERE UserId = @UserId;
END;