CREATE   PROCEDURE corp.sp_PlatformAccounts_Delete 
    @Id INT 
AS 
BEGIN 
    DELETE FROM corp.PlatformAccounts WHERE Id = @Id; 
END;