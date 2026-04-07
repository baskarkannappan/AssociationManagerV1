-- 8. Update sp_AssociationProfile_Get to include status from corp.Associations
CREATE   PROCEDURE assoc.sp_AssociationProfile_Get
    @AssociationId INT
AS
BEGIN
    SELECT p.*, a.Status
    FROM assoc.AssociationProfile p
    JOIN corp.Associations a ON p.AssociationId = a.AssociationId
    WHERE p.AssociationId = @AssociationId;
END;