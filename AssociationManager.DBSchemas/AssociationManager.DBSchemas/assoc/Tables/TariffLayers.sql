CREATE TABLE [assoc].[TariffLayers] (
    [TariffLayerId]      INT             IDENTITY (1, 1) NOT NULL,
    [TariffGroupId]      INT             NOT NULL,
    [TenantId]           INT             NOT NULL,
    [Name]               NVARCHAR (100)  NOT NULL,
    [BaseRate]           DECIMAL (18, 2) NOT NULL,
    [Frequency]          INT             NOT NULL,
    [CalculationType]    INT             NOT NULL,
    [AccountingCategory] NVARCHAR (100)  NULL,
    [AssociationId]      INT             NULL,
    PRIMARY KEY CLUSTERED ([TariffLayerId] ASC),
    CONSTRAINT [FK_TariffLayers_Groups] FOREIGN KEY ([TariffGroupId]) REFERENCES [assoc].[TariffGroups] ([TariffGroupId]),
    CONSTRAINT [FK_TariffLayers_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);

