CREATE   PROCEDURE assoc.sp_Meetings_Insert
    @AssociationId INT,
    @Title NVARCHAR(200),
    @MeetingDate DATETIME2,
    @Description NVARCHAR(MAX),
    @CreatedBy INT
AS
BEGIN
    INSERT INTO assoc.Meetings (AssociationId, Title, MeetingDate, Description, CreatedBy)
    VALUES (@AssociationId, @Title, @MeetingDate, @Description, @CreatedBy);
    SELECT SCOPE_IDENTITY();
END;