-- REFRESH TOKENS
CREATE   PROCEDURE corp.sp_RefreshTokens_GetByToken @Token NVARCHAR(MAX) AS 
BEGIN SELECT * FROM corp.RefreshTokens WHERE Token = @Token; END