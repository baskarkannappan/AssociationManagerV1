CREATE TABLE [corp].[SubscriptionPlans] (
    [PlanId]        INT             IDENTITY (1, 1) NOT NULL,
    [Name]          NVARCHAR (100)  NOT NULL,
    [BasePrice]     DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [PricePerAsset] DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [IsActive]      BIT             DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([PlanId] ASC)
);

