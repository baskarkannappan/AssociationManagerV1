-- 3. Pets Update
CREATE   PROCEDURE assoc.sp_Pets_Update
    @PetId INT,
    @AssetId INT,
    @TenantId INT,
    @AssociationId INT,
    @Name NVARCHAR(100),
    @Species NVARCHAR(100),
    @Breed NVARCHAR(100) = NULL,
    @TagNumber NVARCHAR(50) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.Pets
    SET AssetId = @AssetId,
        TenantId = @TenantId,
        AssociationId = @AssociationId,
        Name = @Name,
        Species = @Species,
        Breed = @Breed,
        TagNumber = @TagNumber,
        IsActive = @IsActive
    WHERE PetId = @PetId AND TenantId = @TenantId AND AssociationId = @AssociationId;
END