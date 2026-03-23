CREATE   PROCEDURE assoc.sp_Assets_GetByParentId @ParentId INT = NULL, @TenantId INT, @AssociationId INT AS 
BEGIN
    IF @ParentId IS NULL
        SELECT * FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId IS NULL;
    ELSE
        SELECT * FROM assoc.Assets WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND ParentId = @ParentId;
END