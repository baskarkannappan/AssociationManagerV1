CREATE TABLE [assoc].[Pets] (
    [PetId]         INT            IDENTITY (1, 1) NOT NULL,
    [AssetId]       INT            NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Name]          NVARCHAR (100) NOT NULL,
    [Species]       NVARCHAR (50)  NOT NULL,
    [Breed]         NVARCHAR (100) NULL,
    [TagNumber]     NVARCHAR (100) NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([PetId] ASC),
    CONSTRAINT [FK_Pets_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Pets_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Pets_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Pets_AssociationId]
    ON [assoc].[Pets]([AssociationId] ASC);

