CREATE   PROCEDURE assoc.sp_CommitteeMembers_Insert
    @AssociationId INT,
    @MemberId INT,
    @MemberName NVARCHAR(255) = NULL,
    @RoleId INT,
    @StartDate DATETIME2,
    @EndDate DATETIME2 = NULL,
    @IsActive BIT
AS
BEGIN
    INSERT INTO assoc.CommitteeMembers (AssociationId, MemberId, MemberName, RoleId, StartDate, EndDate, IsActive)
    VALUES (@AssociationId, @MemberId, @MemberName, @RoleId, @StartDate, @EndDate, @IsActive);
    SELECT SCOPE_IDENTITY();
END;