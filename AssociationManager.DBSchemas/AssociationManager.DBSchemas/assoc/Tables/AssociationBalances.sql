CREATE TABLE [assoc].[AssociationBalances] (
    [AssociationId]      INT             NOT NULL,
    [TenantId]           INT             NOT NULL,
    [TotalOutstanding]   DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalAdvanceCredits] DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [UnitsWithCredit]    INT             DEFAULT ((0)) NOT NULL,
    [TotalRevenue]       DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalMembers]       INT             DEFAULT ((0)) NOT NULL,
    [CommitteeMembers]   INT             DEFAULT ((0)) NOT NULL,
    [PendingWorkOrders]  INT             DEFAULT ((0)) NOT NULL,
    [LastUpdated]        DATETIME        DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([AssociationId] ASC),
    CONSTRAINT [FK_AssociationBalances_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_AssociationBalances_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);

GO
CREATE NONCLUSTERED INDEX [IX_AssociationBalances_TenantId]
    ON [assoc].[AssociationBalances]([TenantId] ASC);
GO
