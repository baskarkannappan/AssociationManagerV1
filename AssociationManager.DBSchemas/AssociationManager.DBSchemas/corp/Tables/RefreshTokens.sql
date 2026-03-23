CREATE TABLE [corp].[RefreshTokens] (
    [RefreshTokenId] INT            IDENTITY (1, 1) NOT NULL,
    [UserId]         INT            NOT NULL,
    [Token]          NVARCHAR (500) NOT NULL,
    [ExpiryDate]     DATETIME       NOT NULL,
    [CreatedDate]    DATETIME       DEFAULT (getdate()) NOT NULL,
    [IsRevoked]      BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RefreshTokenId] ASC),
    CONSTRAINT [FK_RefreshTokens_Users] FOREIGN KEY ([UserId]) REFERENCES [corp].[Users] ([UserId])
);

