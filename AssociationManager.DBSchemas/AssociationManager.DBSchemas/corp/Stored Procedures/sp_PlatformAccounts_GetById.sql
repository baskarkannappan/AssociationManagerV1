-- 2. Stored Procedures

CREATE   PROCEDURE corp.sp_PlatformAccounts_GetById 
    @Id INT 
AS 
BEGIN 
    SELECT * FROM corp.PlatformAccounts WHERE Id = @Id; 
END;