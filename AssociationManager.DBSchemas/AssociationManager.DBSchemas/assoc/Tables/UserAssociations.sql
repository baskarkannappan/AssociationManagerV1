CREATE TABLE [assoc].[UserAssociations] (
    [UserId]        INT           NOT NULL,
    [AssociationId] INT           NOT NULL,
    [Role]          NVARCHAR (50) NOT NULL,
    [CreatedDate]   DATETIME2 (7) DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC, [AssociationId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    FOREIGN KEY ([UserId]) REFERENCES [assoc].[Users] ([UserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUserAssociations_AssociationId]
    ON [assoc].[UserAssociations]([AssociationId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AssocUserAssociations_UserId]
    ON [assoc].[UserAssociations]([UserId] ASC);

