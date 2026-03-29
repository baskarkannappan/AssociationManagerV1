CREATE   PROCEDURE assoc.sp_Votes_Insert
    @ElectionId INT,
    @MemberId INT,
    @CandidateId INT
AS
BEGIN
    INSERT INTO assoc.Votes (ElectionId, MemberId, CandidateId) VALUES (@ElectionId, @MemberId, @CandidateId);
END;