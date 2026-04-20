CREATE TRIGGER assoc.tr_CommitteeMembers_SyncDashboard 
ON assoc.CommitteeMembers 
AFTER INSERT, UPDATE, DELETE 
AS 
BEGIN 
    SET NOCOUNT ON; 
    DECLARE @Aid INT; 
    SELECT TOP 1 @Aid = AssociationId 
    FROM (SELECT AssociationId FROM inserted UNION SELECT AssociationId FROM deleted) x; 
    IF @Aid IS NOT NULL EXEC assoc.sp_AssociationBalances_Sync @AssociationId = @Aid; 
END;
