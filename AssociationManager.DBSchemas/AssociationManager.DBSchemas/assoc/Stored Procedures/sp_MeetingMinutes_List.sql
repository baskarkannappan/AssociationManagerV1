CREATE   PROCEDURE assoc.sp_MeetingMinutes_List
    @MeetingId INT
AS
BEGIN
    SELECT * FROM assoc.MeetingMinutes WHERE MeetingId = @MeetingId;
END;