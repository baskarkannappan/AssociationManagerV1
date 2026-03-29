-- Governance Stored Procedures

-- 1. Profile
CREATE   PROCEDURE assoc.sp_AssociationProfile_Get
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.AssociationProfile WHERE AssociationId = @AssociationId;
END;