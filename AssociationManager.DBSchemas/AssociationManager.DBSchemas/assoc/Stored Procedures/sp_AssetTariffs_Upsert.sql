CREATE PROCEDURE assoc.sp_AssetTariffs_Upsert
    @AssetId INT,
    @TariffLayerId INT,
    @CustomAmount DECIMAL(18,2) = NULL,
    @IsActive BIT = 1,
    @IsRecurring BIT = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AssetTariffs WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId)
    BEGIN
        UPDATE assoc.AssetTariffs
        SET CustomAmount = @CustomAmount,
            IsActive = @IsActive,
            IsRecurring = @IsRecurring
        WHERE AssetId = @AssetId AND TariffLayerId = @TariffLayerId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssetTariffs (AssetId, TariffLayerId, CustomAmount, IsActive, IsRecurring)
        VALUES (@AssetId, @TariffLayerId, @CustomAmount, @IsActive, @IsRecurring);
    END
END