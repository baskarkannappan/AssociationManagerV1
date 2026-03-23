CREATE TABLE [corp].[AssociationSubscriptions] (
    [SubscriptionId]  INT           IDENTITY (1, 1) NOT NULL,
    [AssociationId]   INT           NOT NULL,
    [PlanId]          INT           NOT NULL,
    [Status]          NVARCHAR (50) DEFAULT ('Active') NOT NULL,
    [StartDate]       DATETIME      DEFAULT (getdate()) NOT NULL,
    [NextBillingDate] DATETIME      NOT NULL,
    PRIMARY KEY CLUSTERED ([SubscriptionId] ASC),
    CONSTRAINT [FK_AssociationSubscriptions_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_AssociationSubscriptions_Plans] FOREIGN KEY ([PlanId]) REFERENCES [corp].[SubscriptionPlans] ([PlanId])
);

