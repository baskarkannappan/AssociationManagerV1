CREATE   PROCEDURE assoc.sp_CommitteeMembers_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT cm.*, COALESCE(cm.MemberName, u.Name) as MemberName, cr.RoleName 
    FROM assoc.CommitteeMembers cm
    LEFT JOIN corp.Users u ON cm.MemberId = u.UserId
    JOIN assoc.CommitteeRoles cr ON cm.RoleId = cr.RoleId
    WHERE cm.AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR cm.IsActive = 1);
END;