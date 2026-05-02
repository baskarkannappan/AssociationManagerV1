CREATE TYPE [assoc].[typ_AssetTariffBatch] AS TABLE (
    [AssetId]       INT             NOT NULL,
    [TariffLayerId] INT             NOT NULL,
    [CustomAmount]  DECIMAL (18, 2) NULL,
    [IsActive]      BIT             NOT NULL,
    [IsRecurring]   BIT             NOT NULL
);
