CREATE   PROCEDURE corp.sp_RefreshTokens_Delete @UserId INT AS 
BEGIN DELETE FROM corp.RefreshTokens WHERE UserId = @UserId; END