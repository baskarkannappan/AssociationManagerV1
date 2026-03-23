CREATE TABLE [assoc].[Vehicles] (
    [VehicleId]     INT            IDENTITY (1, 1) NOT NULL,
    [AssetId]       INT            NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Make]          NVARCHAR (100) NOT NULL,
    [Model]         NVARCHAR (100) NOT NULL,
    [LicensePlate]  NVARCHAR (50)  NOT NULL,
    [Color]         NVARCHAR (50)  NULL,
    [ParkingSlot]   NVARCHAR (100) NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([VehicleId] ASC),
    CONSTRAINT [FK_Vehicles_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Vehicles_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Vehicles_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Vehicles_AssociationId]
    ON [assoc].[Vehicles]([AssociationId] ASC);

