-- Script0100_GlobalAssociationDeactivation.sql
-- Enable global deactivation for associations by removing TenantId restriction

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[corp].[sp_Associations_Delete]') AND type in (N'P', N'PC'))
BEGIN
    EXEC('ALTER PROCEDURE corp.sp_Associations_Delete @Id INT AS 
    BEGIN 
        UPDATE corp.Associations SET Status = ''Deactivated'' WHERE AssociationId = @Id; 
    END')
END
GO
