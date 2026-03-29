CREATE   PROCEDURE assoc.sp_ByeLaws_Update
    @ByeLawId INT,
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
    UPDATE assoc.ByeLaws SET 
        Title = @Title, 
        Description = @Description, 
        EffectiveDate = @EffectiveDate, 
        Version = @Version, 
        IsActive = @IsActive,
        DocumentContent = @DocumentContent,
        FileName = @FileName,
        ContentType = @ContentType
    WHERE ByeLawId = @ByeLawId;
END;