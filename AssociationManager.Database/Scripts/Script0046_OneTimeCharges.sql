IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('assoc.AssetTariffs') AND name = 'IsRecurring')
BEGIN
    ALTER TABLE assoc.AssetTariffs ADD IsRecurring BIT NOT NULL DEFAULT 1;
END
GO

-- Update Stored Procedures
GO
ALTER PROCEDURE assoc.sp_AssetTariffs_Upsert
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
GO

ALTER PROCEDURE assoc.sp_AssetTariffs_GetByAssetId
    @AssetId INT
AS
BEGIN
    SELECT at.*, tl.Name AS ChargeName
    FROM assoc.AssetTariffs at
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    WHERE at.AssetId = @AssetId;
END
GO

ALTER PROCEDURE assoc.sp_AssetTariffs_GetActiveByTenantId
    @TenantId INT
AS
BEGIN
    SELECT at.*, tl.Name AS ChargeName
    FROM assoc.AssetTariffs at
    JOIN assoc.TariffLayers tl ON at.TariffLayerId = tl.TariffLayerId
    WHERE tl.TenantId = @TenantId AND at.IsActive = 1;
END
GO
