CREATE TABLE [assoc].[AssetTariffs] (
    [AssetId]       INT             NOT NULL,
    [TariffLayerId] INT             NOT NULL,
    [CustomAmount]  DECIMAL (18, 2) NULL,
    [IsActive]      BIT             DEFAULT ((1)) NOT NULL,
    [IsRecurring]   BIT             DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([AssetId] ASC, [TariffLayerId] ASC),
    CONSTRAINT [FK_AssetTariffs_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_AssetTariffs_Layers] FOREIGN KEY ([TariffLayerId]) REFERENCES [assoc].[TariffLayers] ([TariffLayerId])
);

