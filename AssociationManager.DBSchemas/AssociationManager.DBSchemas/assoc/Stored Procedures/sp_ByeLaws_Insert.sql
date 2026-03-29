CREATE   PROCEDURE assoc.sp_ByeLaws_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @EffectiveDate DATETIME2,
    @Version NVARCHAR(50),
    @IsActive BIT,
    @DocumentContent VARBINARY(MAX) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @ContentType NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO assoc.ByeLaws (AssociationId, Title, Description, EffectiveDate, Version, IsActive, DocumentContent, FileName, ContentType)
    VALUES (@AssociationId, @Title, @Description, @EffectiveDate, @Version, @IsActive, @DocumentContent, @FileName, @ContentType);
    SELECT SCOPE_IDENTITY();
END;