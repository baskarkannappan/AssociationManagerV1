-- PETS
CREATE   PROCEDURE assoc.sp_Pets_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Pets 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END