-- 2. Committee
CREATE   PROCEDURE assoc.sp_CommitteeRoles_List
AS
BEGIN
    SELECT * FROM assoc.CommitteeRoles;
END;