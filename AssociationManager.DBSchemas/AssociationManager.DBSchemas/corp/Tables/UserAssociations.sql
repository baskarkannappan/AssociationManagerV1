CREATE TABLE [corp].[UserAssociations] (
    [UserId]      INT           NOT NULL,
    [TenantId]    INT           NOT NULL,
    [Role]        NVARCHAR (50) NOT NULL,
    [CreatedDate] DATETIME2 (7) DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC, [TenantId] ASC),
    FOREIGN KEY ([TenantId]) REFERENCES [corp].[Tenants] ([TenantId]),
    FOREIGN KEY ([UserId]) REFERENCES [corp].[Users] ([UserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_UserAssociations_TenantId]
    ON [corp].[UserAssociations]([TenantId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_UserAssociations_UserId]
    ON [corp].[UserAssociations]([UserId] ASC);

