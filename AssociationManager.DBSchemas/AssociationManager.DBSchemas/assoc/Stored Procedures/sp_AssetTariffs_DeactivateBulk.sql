CREATE TYPE assoc.IntegerList AS TABLE (
    Id INT
);
GO

CREATE PROCEDURE assoc.sp_AssetTariffs_DeactivateBulk
    @AssetIds assoc.IntegerList READONLY,
    @TariffLayerId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE assoc.AssetTariffs
    SET IsActive = 0
    WHERE TariffLayerId = @TariffLayerId 
    AND AssetId IN (SELECT Id FROM @AssetIds);
END
GO
