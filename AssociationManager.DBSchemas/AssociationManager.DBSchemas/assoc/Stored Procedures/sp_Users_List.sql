
CREATE   PROCEDURE assoc.sp_Users_List
AS
BEGIN
    SELECT * FROM assoc.Users ORDER BY Name;
END;