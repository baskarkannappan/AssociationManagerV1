CREATE TABLE [assoc].[FineSettings] (
    [FineSettingsId]  INT             IDENTITY (1, 1) NOT NULL,
    [AssociationId]   INT             NOT NULL,
    [TenantId]        INT             NOT NULL,
    [StrategyType]    NVARCHAR (50)   DEFAULT ('None') NOT NULL,
    [FineValue]       DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [GracePeriodDays] INT             DEFAULT ((0)) NOT NULL,
    [IsCompounding]   BIT             DEFAULT ((0)) NOT NULL,
    [Frequency]       NVARCHAR (20)   DEFAULT ('Monthly') NOT NULL,
    [LastUpdated]     DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [LastUpdatedBy]   NVARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([FineSettingsId] ASC),
    CONSTRAINT [FK_FineSettings_Association] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId])
);


GO
CREATE NONCLUSTERED INDEX [IX_FineSettings_Association]
    ON [assoc].[FineSettings]([AssociationId] ASC);

