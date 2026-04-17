CREATE   PROCEDURE assoc.sp_Persons_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Persons WHERE AssociationId = @AssociationId AND IsActive = 1; END