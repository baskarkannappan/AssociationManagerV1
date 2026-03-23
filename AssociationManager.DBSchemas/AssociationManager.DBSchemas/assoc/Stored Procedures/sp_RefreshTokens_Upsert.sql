
-- REFRESH TOKENS PROC FIX
CREATE   PROCEDURE assoc.sp_RefreshTokens_Upsert @UserId INT, @Token NVARCHAR(MAX), @ExpiryDate DATETIME, @CreatedDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.RefreshTokens WHERE UserId = @UserId)
        UPDATE assoc.RefreshTokens SET Token = @Token, ExpiryDate = @ExpiryDate WHERE UserId = @UserId
    ELSE
        INSERT INTO assoc.RefreshTokens (UserId, Token, ExpiryDate, CreatedDate) VALUES (@UserId, @Token, @ExpiryDate, @CreatedDate);
END