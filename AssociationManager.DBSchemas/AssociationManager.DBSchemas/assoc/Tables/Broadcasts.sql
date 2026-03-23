CREATE TABLE [assoc].[Broadcasts] (
    [BroadcastId]   INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Title]         NVARCHAR (200) NOT NULL,
    [Content]       NVARCHAR (MAX) NOT NULL,
    [Category]      NVARCHAR (50)  DEFAULT ('General') NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [CreatedBy]     INT            NOT NULL,
    [IsPinned]      BIT            DEFAULT ((0)) NOT NULL,
    [ExpiresDate]   DATETIME       NULL,
    [AssetId]       INT            NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([BroadcastId] ASC),
    CONSTRAINT [FK_Broadcasts_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_Broadcasts_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Broadcasts_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Broadcasts_AssociationId]
    ON [assoc].[Broadcasts]([AssociationId] ASC);

