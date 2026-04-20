CREATE TRIGGER corp.tr_Associations_SyncDashboard 
ON corp.Associations 
AFTER INSERT 
AS 
BEGIN 
    SET NOCOUNT ON; 
    DECLARE @Aid INT; 
    SELECT TOP 1 @Aid = AssociationId 
    FROM inserted; 
    IF @Aid IS NOT NULL EXEC assoc.sp_AssociationBalances_Sync @AssociationId = @Aid; 
END;
