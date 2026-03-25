CREATE TABLE [assoc].[Votes] (
    [VoteId]      INT      IDENTITY (1, 1) NOT NULL,
    [ElectionId]  INT      NOT NULL,
    [MemberId]    INT      NOT NULL,
    [CandidateId] INT      NOT NULL,
    [VoteDate]    DATETIME DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([VoteId] ASC),
    FOREIGN KEY ([CandidateId]) REFERENCES [assoc].[Candidates] ([CandidateId]),
    FOREIGN KEY ([ElectionId]) REFERENCES [assoc].[Elections] ([ElectionId]),
    FOREIGN KEY ([MemberId]) REFERENCES [corp].[Users] ([UserId]),
    CONSTRAINT [UQ_Election_Member] UNIQUE NONCLUSTERED ([ElectionId] ASC, [MemberId] ASC)
);

