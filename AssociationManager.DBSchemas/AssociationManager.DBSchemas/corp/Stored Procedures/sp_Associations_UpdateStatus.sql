-- 7. Add sp_Associations_UpdateStatus
CREATE   PROCEDURE corp.sp_Associations_UpdateStatus @Id INT, @Status NVARCHAR(50) AS 
BEGIN 
    UPDATE corp.Associations SET Status = @Status WHERE AssociationId = @Id; 
END