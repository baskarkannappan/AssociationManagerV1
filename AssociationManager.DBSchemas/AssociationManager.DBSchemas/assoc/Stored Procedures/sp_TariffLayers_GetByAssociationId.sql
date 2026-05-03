CREATE PROCEDURE assoc.sp_TariffLayers_GetByAssociationId
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT tl.* 
    FROM assoc.TariffLayers tl
    INNER JOIN assoc.TariffGroups tg ON tl.TariffGroupId = tg.TariffGroupId
    WHERE tg.AssociationId = @AssociationId AND tg.TenantId = @TenantId;
END
GO
