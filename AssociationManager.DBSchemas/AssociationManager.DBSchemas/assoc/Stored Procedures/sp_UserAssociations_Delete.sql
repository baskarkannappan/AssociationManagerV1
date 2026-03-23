CREATE   PROCEDURE assoc.sp_UserAssociations_Delete @UserId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId; END