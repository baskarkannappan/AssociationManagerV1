CREATE   PROCEDURE assoc.sp_RefreshTokens_Delete @UserId INT AS 
BEGIN DELETE FROM assoc.RefreshTokens WHERE UserId = @UserId; END