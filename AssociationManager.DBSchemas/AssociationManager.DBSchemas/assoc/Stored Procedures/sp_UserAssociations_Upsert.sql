CREATE   PROCEDURE assoc.sp_UserAssociations_Upsert @UserId INT, @AssociationId INT, @Role NVARCHAR(50) AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM assoc.UserAssociations WHERE UserId = @UserId AND AssociationId = @AssociationId)
        UPDATE assoc.UserAssociations SET Role = @Role WHERE UserId = @UserId AND AssociationId = @AssociationId
    ELSE
        INSERT INTO assoc.UserAssociations (UserId, AssociationId, Role) VALUES (@UserId, @AssociationId, @Role);
END