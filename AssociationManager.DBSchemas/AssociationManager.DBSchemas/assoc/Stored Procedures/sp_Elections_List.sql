CREATE   PROCEDURE assoc.sp_Elections_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.Elections 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;