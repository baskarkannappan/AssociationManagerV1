-- STORED PROCEDURES FOR ASSOC USER ASSOCIATIONS
CREATE   PROCEDURE assoc.sp_UserAssociations_CheckExists @UserId INT, @AssociationId INT AS 
BEGIN SELECT COUNT(1) FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId; END