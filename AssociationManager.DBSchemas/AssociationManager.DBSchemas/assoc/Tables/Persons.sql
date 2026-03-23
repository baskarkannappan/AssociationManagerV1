CREATE TABLE [assoc].[Persons] (
    [PersonId]      INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [FirstName]     NVARCHAR (100) NOT NULL,
    [LastName]      NVARCHAR (100) NOT NULL,
    [Email]         NVARCHAR (200) NULL,
    [Phone]         NVARCHAR (50)  NULL,
    [PhotoUrl]      NVARCHAR (500) NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [AssociationId] INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC),
    CONSTRAINT [FK_Persons_Associations] FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    CONSTRAINT [FK_Persons_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);


GO
CREATE NONCLUSTERED INDEX [IX_Persons_AssociationId]
    ON [assoc].[Persons]([AssociationId] ASC);

