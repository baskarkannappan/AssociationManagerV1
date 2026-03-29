CREATE   PROCEDURE assoc.sp_Votes_Check
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    SELECT COUNT(1) FROM assoc.Votes WHERE ElectionId = @ElectionId AND MemberId = @MemberId;
END;