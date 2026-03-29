CREATE   PROCEDURE assoc.sp_ByeLaws_GetById
    @id INT
AS
BEGIN
    SELECT * FROM assoc.ByeLaws WHERE ByeLawId = @id;
END;