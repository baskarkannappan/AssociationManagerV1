CREATE TABLE [assoc].[CommitteeMembers] (
    [CommitteeMemberId] INT            IDENTITY (1, 1) NOT NULL,
    [AssociationId]     INT            NOT NULL,
    [MemberId]          INT            NULL,
    [RoleId]            INT            NOT NULL,
    [StartDate]         DATETIME       NOT NULL,
    [EndDate]           DATETIME       NULL,
    [IsActive]          BIT            DEFAULT ((1)) NULL,
    [MemberName]        NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([CommitteeMemberId] ASC),
    FOREIGN KEY ([AssociationId]) REFERENCES [corp].[Associations] ([AssociationId]),
    FOREIGN KEY ([MemberId]) REFERENCES [corp].[Users] ([UserId]),
    FOREIGN KEY ([RoleId]) REFERENCES [assoc].[CommitteeRoles] ([RoleId])
);


GO
CREATE   TRIGGER assoc.tr_CommitteeMembers_SyncDashboard ON assoc.CommitteeMembers AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; DECLARE @Aid INT; SELECT TOP 1 @Aid = AssociationId FROM (SELECT AssociationId FROM inserted UNION SELECT AssociationId FROM deleted) x; IF @Aid IS NOT NULL EXEC assoc.sp_AssociationBalances_Sync @AssociationId = @Aid; END;