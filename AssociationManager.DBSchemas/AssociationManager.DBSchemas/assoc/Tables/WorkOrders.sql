CREATE TABLE [assoc].[WorkOrders] (
    [WorkOrderId]   INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [AssetId]       INT            NULL,
    [Title]         NVARCHAR (200) NOT NULL,
    [Description]   NVARCHAR (MAX) NULL,
    [Priority]      NVARCHAR (50)  DEFAULT ('Medium') NOT NULL,
    [Status]        NVARCHAR (50)  DEFAULT ('Open') NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [CreatedBy]     INT            NOT NULL,
    [AssignedTo]    NVARCHAR (200) NULL,
    [CompletedDate] DATETIME       NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkOrderId] ASC),
    CONSTRAINT [FK_WorkOrders_Assets] FOREIGN KEY ([AssetId]) REFERENCES [assoc].[Assets] ([AssetId]),
    CONSTRAINT [FK_WorkOrders_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_WorkOrders_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);




GO
CREATE NONCLUSTERED INDEX [IX_WorkOrders_AssociationId]
    ON [assoc].[WorkOrders]([AssociationId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_WorkOrders_TenantId]
    ON [assoc].[WorkOrders]([TenantId] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_WorkOrders_Status]
    ON [assoc].[WorkOrders]([Status] ASC);



GO
CREATE   TRIGGER assoc.tr_WorkOrders_SyncDashboard ON assoc.WorkOrders AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; DECLARE @Aid INT; SELECT TOP 1 @Aid = AssociationId FROM (SELECT AssociationId FROM inserted UNION SELECT AssociationId FROM deleted) x; IF @Aid IS NOT NULL EXEC assoc.sp_AssociationBalances_Sync @AssociationId = @Aid; END;