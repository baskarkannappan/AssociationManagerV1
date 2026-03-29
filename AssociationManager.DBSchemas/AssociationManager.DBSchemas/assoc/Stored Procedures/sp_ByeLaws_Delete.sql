CREATE   PROCEDURE assoc.sp_ByeLaws_Delete
    @id INT
AS
BEGIN
    DELETE FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;