CREATE NONCLUSTERED INDEX [IX_Transactions_Asset_Association]
    ON [assoc].[Transactions]([AssetId] ASC, [AssociationId] ASC);
