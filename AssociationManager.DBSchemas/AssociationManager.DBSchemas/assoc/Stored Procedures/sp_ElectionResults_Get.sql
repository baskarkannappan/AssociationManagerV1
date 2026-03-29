CREATE   PROCEDURE assoc.sp_ElectionResults_Get
    @ElectionId INT
AS
BEGIN
    SELECT u.Name as CandidateName, COUNT(v.VoteId) as VoteCount
    FROM assoc.Candidates c
    JOIN corp.Users u ON c.MemberId = u.UserId
    LEFT JOIN assoc.Votes v ON c.CandidateId = v.CandidateId
    WHERE c.ElectionId = @ElectionId
    GROUP BY u.Name;
END;