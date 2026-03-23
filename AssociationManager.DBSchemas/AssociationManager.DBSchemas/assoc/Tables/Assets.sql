CREATE TABLE [assoc].[Assets] (
    [AssetId]       INT            IDENTITY (1, 1) NOT NULL,
    [ParentId]      INT            NULL,
    [TenantId]      INT            NOT NULL,
    [Name]          NVARCHAR (200) NOT NULL,
    [Description]   NVARCHAR (500) NULL,
    [AssetType]     INT            NOT NULL,
    [MetadataJson]  NVARCHAR (MAX) NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [CreatedBy]     INT            NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([AssetId] ASC),
    CONSTRAINT [FK_Assets_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Assets_Parent] FOREIGN KEY ([ParentId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Assets_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_AssociationId]
    ON [assoc].[Assets]([AssociationId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_AssetType]
    ON [assoc].[Assets]([AssetType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_ParentId]
    ON [assoc].[Assets]([ParentId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Assets_TenantId]
    ON [assoc].[Assets]([TenantId] ASC);

