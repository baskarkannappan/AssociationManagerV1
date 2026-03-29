CREATE   PROCEDURE assoc.sp_CommitteeMembers_Update
    @CommitteeMemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE assoc.CommitteeMembers 
    SET RoleId = @RoleId, 
        MemberName = @MemberName, 
        StartDate = @StartDate, 
        EndDate = @EndDate, 
        IsActive = @IsActive 
    WHERE CommitteeMemberId = @CommitteeMemberId;
END;