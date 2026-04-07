CREATE TABLE [corp].[Associations] (
    [AssociationId]         INT             IDENTITY (1, 1) NOT NULL,
    [TenantId]              INT             NOT NULL,
    [Name]                  NVARCHAR (200)  NOT NULL,
    [Description]           NVARCHAR (500)  NULL,
    [CreatedDate]           DATETIME        DEFAULT (getdate()) NOT NULL,
    [CreatedBy]             INT             NULL,
    [PlatformAccountId]     INT             NULL,
    [AdminPaysFee]          BIT             DEFAULT ((1)) NOT NULL,
    [PlatformWalletBalance] DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [Status]                NVARCHAR (50)   DEFAULT ('Active') NOT NULL,
    [AdminEmail]            NVARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([AssociationId] ASC),
    CONSTRAINT [FK_Associations_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);

