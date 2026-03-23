CREATE   PROCEDURE corp.sp_RefreshTokens_Upsert @UserId INT, @Token NVARCHAR(MAX), @ExpiryDate DATETIME, @CreatedDate DATETIME AS 
BEGIN
    IF EXISTS (SELECT 1 FROM corp.RefreshTokens WHERE UserId = @UserId)
        UPDATE corp.RefreshTokens SET Token = @Token, ExpiryDate = @ExpiryDate WHERE UserId = @UserId
    ELSE
        INSERT INTO corp.RefreshTokens (UserId, Token, ExpiryDate, CreatedDate) VALUES (@UserId, @Token, @ExpiryDate, @CreatedDate);
END