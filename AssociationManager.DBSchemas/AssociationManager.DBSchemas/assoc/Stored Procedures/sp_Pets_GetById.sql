CREATE   PROCEDURE assoc.sp_Pets_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Pets 
    WHERE PetId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId;
END;