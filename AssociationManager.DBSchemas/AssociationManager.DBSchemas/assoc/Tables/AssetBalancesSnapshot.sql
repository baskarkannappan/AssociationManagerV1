CREATE TABLE [assoc].[AssetBalancesSnapshot] (
    [AssetId]           INT             NOT NULL,
    [TenantId]          INT             NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [OutstandingAmount] DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [PaidAmount]        DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [AdvanceBalance]    DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [LastUpdated]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([AssetId] ASC),
    CONSTRAINT [FK_AssetBalancesSnapshot_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId])
);
GO

CREATE INDEX [IX_AssetBalancesSnapshot_Association] ON [assoc].[AssetBalancesSnapshot] ([AssociationId], [TenantId]);
GO
