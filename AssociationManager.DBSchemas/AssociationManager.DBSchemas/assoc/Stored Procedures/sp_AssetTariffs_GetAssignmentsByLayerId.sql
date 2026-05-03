CREATE PROCEDURE assoc.sp_AssetTariffs_GetAssignmentsByLayerId
    @LayerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT at.*, a.Name as AssetName 
    FROM assoc.AssetTariffs at
    INNER JOIN assoc.Assets a ON at.AssetId = a.AssetId
    WHERE at.TariffLayerId = @LayerId AND at.IsActive = 1;
END
GO
