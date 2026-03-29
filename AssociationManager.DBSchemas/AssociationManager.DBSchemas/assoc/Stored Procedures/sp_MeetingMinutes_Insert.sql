CREATE   PROCEDURE assoc.sp_MeetingMinutes_Insert
    @MeetingId INT,
    @Notes NVARCHAR(MAX),
    @DocumentUrl NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO assoc.MeetingMinutes (MeetingId, Notes, DocumentUrl)
    VALUES (@MeetingId, @Notes, @DocumentUrl);
    SELECT SCOPE_IDENTITY();
END;