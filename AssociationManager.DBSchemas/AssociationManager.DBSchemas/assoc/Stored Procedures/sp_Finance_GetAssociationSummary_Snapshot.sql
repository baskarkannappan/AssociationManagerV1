
-- 3.4 sp_Finance_GetAssociationSummary_Snapshot
CREATE   PROCEDURE assoc.sp_Finance_GetAssociationSummary_Snapshot
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM assoc.AssociationBalances WHERE AssociationId = @AssociationId)
        SELECT TotalOutstanding, TotalAdvanceCredits as TotalCredits, UnitsWithCredit, 1 as IsSnapshot FROM assoc.AssociationBalances WHERE AssociationId = @AssociationId;
    ELSE
        EXEC assoc.sp_Finance_GetAssociationSummary @AssociationId, @TenantId;
END
GO
