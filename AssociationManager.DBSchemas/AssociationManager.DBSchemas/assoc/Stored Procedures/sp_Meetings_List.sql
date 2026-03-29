-- 4. Meetings
CREATE   PROCEDURE assoc.sp_Meetings_List
    @AssociationId INT
AS
BEGIN
    SELECT * FROM assoc.Meetings WHERE AssociationId = @AssociationId;
END;