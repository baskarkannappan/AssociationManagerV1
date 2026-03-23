CREATE TABLE [corp].[Tenants] (
    [TenantId]    INT            IDENTITY (1, 1) NOT NULL,
    [Name]        NVARCHAR (200) NOT NULL,
    [CreatedDate] DATETIME       DEFAULT (getdate()) NOT NULL,
    [IsActive]    BIT            DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([TenantId] ASC)
);

