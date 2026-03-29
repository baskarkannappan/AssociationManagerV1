CREATE TABLE [corp].[PlatformInvoices] (
    [PlatformInvoiceId] INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]     INT             NOT NULL,
    [PlanId]            INT             NOT NULL,
    [Amount]            DECIMAL (18, 2) NOT NULL,
    [BillingDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [DueDate]           DATETIME        NOT NULL,
    [Status]            NVARCHAR (50)   DEFAULT ('Unpaid') NOT NULL,
    [CreatedDate]       DATETIME        DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([PlatformInvoiceId] ASC),
    CONSTRAINT [FK_PlatformInvoices_Association] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_PlatformInvoices_Plan] FOREIGN KEY ([PlanId]) REFERENCES [corp].[SubscriptionPlans] ([PlanId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_PlatformInvoices_Assoc_Period]
    ON [corp].[PlatformInvoices]([AssociationId] ASC, [BillingDate] ASC);

