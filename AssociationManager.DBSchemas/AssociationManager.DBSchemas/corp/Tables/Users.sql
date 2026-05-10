CREATE TABLE [corp].[Users] (
    [UserId]        INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NOT NULL,
    [GoogleId]      NVARCHAR (200) NULL,
    [SubjectId]     NVARCHAR (255) NULL,
    [Email]         NVARCHAR (200) NOT NULL,
    [Name]          NVARCHAR (200) NOT NULL,
    [PictureUrl]    NVARCHAR (500) NULL,
    [CreatedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    [LastLoginDate] DATETIME       NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    [Role]          NVARCHAR (50)  DEFAULT ('User') NOT NULL,
    [AssociationId] INT            NULL,
    [MetadataJson]  NVARCHAR (MAX) NULL,
    [PasswordHash]  NVARCHAR (500) NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT [FK_Users_Tenants] FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId])
);

