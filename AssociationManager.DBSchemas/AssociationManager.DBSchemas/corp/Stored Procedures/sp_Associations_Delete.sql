-- 6. Update sp_Associations_Delete to Deactivate instead
CREATE   PROCEDURE corp.sp_Associations_Delete @Id INT AS 
BEGIN 
    UPDATE corp.Associations SET Status = 'Deactivated' WHERE AssociationId = @Id; 
END