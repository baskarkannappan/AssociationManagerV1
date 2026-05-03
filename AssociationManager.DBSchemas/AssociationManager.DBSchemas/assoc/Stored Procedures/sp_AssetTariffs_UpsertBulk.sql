CREATE PROCEDURE [assoc].[sp_AssetTariffs_UpsertBulk]
    @TariffAssignments [assoc].[typ_AssetTariffBatch] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [assoc].[AssetTariffs] AS target
    USING @TariffAssignments AS source
    ON (target.AssetId = source.AssetId AND target.TariffLayerId = source.TariffLayerId)
    WHEN MATCHED THEN
        UPDATE SET 
            CustomAmount = source.CustomAmount,
            IsActive = source.IsActive,
            IsRecurring = source.IsRecurring
    WHEN NOT MATCHED THEN
        INSERT (AssetId, TariffLayerId, CustomAmount, IsActive, IsRecurring)
        VALUES (source.AssetId, source.TariffLayerId, source.CustomAmount, source.IsActive, source.IsRecurring);
END
