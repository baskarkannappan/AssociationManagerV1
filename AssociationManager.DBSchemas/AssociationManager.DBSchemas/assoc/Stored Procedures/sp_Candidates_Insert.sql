CREATE   PROCEDURE assoc.sp_Candidates_Insert
    @ElectionId INT,
    @MemberId INT
AS
BEGIN
    INSERT INTO assoc.Candidates (ElectionId, MemberId) VALUES (@ElectionId, @MemberId);
    SELECT SCOPE_IDENTITY();
END;