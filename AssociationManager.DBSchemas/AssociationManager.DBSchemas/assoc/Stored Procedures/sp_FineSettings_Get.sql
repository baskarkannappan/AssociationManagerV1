-- Stored Procedure for Get
CREATE   PROCEDURE assoc.sp_FineSettings_Get
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM assoc.FineSettings WHERE AssociationId = @AssociationId;
END;