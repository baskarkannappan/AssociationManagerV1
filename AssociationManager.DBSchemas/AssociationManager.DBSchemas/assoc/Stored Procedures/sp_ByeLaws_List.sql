-- 3. Bye-laws
CREATE   PROCEDURE assoc.sp_ByeLaws_List
    @AssociationId INT,
    @ActiveOnly BIT = 1
AS
BEGIN
    SELECT * FROM assoc.ByeLaws 
    WHERE AssociationId = @AssociationId
    AND (@ActiveOnly = 0 OR IsActive = 1);
END;