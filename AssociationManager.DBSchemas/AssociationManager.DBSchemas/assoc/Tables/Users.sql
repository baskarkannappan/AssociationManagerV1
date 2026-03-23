CREATE TABLE [assoc].[Users] (
    [UserId]        INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]      INT            NULL,
    [GoogleId]      NVARCHAR (255) NULL,
    [Email]         NVARCHAR (255) NOT NULL,
    [Name]          NVARCHAR (255) NOT NULL,
    [PictureUrl]    NVARCHAR (MAX) NULL,
    [Role]          NVARCHAR (50)  DEFAULT ('User') NOT NULL,
    [CreatedDate]   DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [LastLoginDate] DATETIME       NULL,
    [IsActive]      BIT            DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUsers_GoogleId]
    ON [assoc].[Users]([GoogleId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUsers_Email]
    ON [assoc].[Users]([Email] ASC);

