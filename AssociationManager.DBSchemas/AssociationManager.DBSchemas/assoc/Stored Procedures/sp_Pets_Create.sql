-- 8. assoc.sp_Pets_Create
CREATE   PROCEDURE assoc.sp_Pets_Create 
    @AssetId INT, 
    @TenantId INT, 
    @AssociationId INT, 
    @Name NVARCHAR(100), 
    @Species NVARCHAR(100), 
    @Breed NVARCHAR(100), 
    @TagNumber NVARCHAR(50), 
    @IsActive BIT 
AS 
BEGIN 
    INSERT INTO assoc.Pets (AssetId, TenantId, AssociationId, Name, Species, Breed, TagNumber, IsActive) 
    VALUES (@AssetId, @TenantId, @AssociationId, @Name, @Species, @Breed, @TagNumber, @IsActive); 

    SELECT SCOPE_IDENTITY();
END