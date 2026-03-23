CREATE TABLE [assoc].[Occupancy] (
    [OccupancyId]      INT      IDENTITY (1, 1) NOT NULL,
    [AssetId]          INT      NOT NULL,
    [PersonId]         INT      NOT NULL,
    [TenantId]         INT      NOT NULL,
    [OccupancyType]    INT      NOT NULL,
    [StartDate]        DATETIME NULL,
    [EndDate]          DATETIME NULL,
    [IsPrimaryContact] BIT      DEFAULT ((0)) NOT NULL,
    [AssociationId]    INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([OccupancyId] ASC),
    CONSTRAINT [FK_Occupancy_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Occupancy_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Occupancy_Persons] FOREIGN KEY ([PersonId]) REFERENCES [assoc].[Persons] ([PersonId]),
    CONSTRAINT [FK_Occupancy_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Occupancy_AssociationId]
    ON [assoc].[Occupancy]([AssociationId] ASC);

