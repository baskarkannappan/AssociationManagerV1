CREATE TABLE [assoc].[RefreshTokens] (
    [RefreshTokenId] INT            IDENTITY (1, 1) NOT NULL,
    [UserId]         INT            NOT NULL,
    [Token]          NVARCHAR (MAX) NOT NULL,
    [ExpiryDate]     DATETIME       NOT NULL,
    [CreatedDate]    DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [IsRevoked]      BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RefreshTokenId] ASC),
    FOREIGN KEY ([UserId]) REFERENCES [assoc].[Users] ([UserId])
);

