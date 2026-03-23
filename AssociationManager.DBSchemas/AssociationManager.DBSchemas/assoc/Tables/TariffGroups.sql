CREATE TABLE [assoc].[TariffGroups] (
    [TariffGroupId] INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [Name]          NVARCHAR (100) NOT NULL,
    [Description]   NVARCHAR (500) NULL,
    [AssociationId] INT            NULL,
    PRIMARY KEY CLUSTERED ([TariffGroupId] ASC),
    CONSTRAINT [FK_TariffGroups_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);

