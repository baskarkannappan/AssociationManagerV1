CREATE PROCEDURE assoc.sp_Finance_GetAssociationSummary_Snapshot
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Try to fetch from snapshot
    IF EXISTS (SELECT 1 FROM assoc.AssociationBalances WHERE AssociationId = @AssociationId)
    BEGIN
        SELECT 
            TotalOutstanding, 
            TotalAdvanceCredits as TotalCredits, -- Align with repository dynamic mapping
            UnitsWithCredit,
            1 as IsSnapshot -- Metadata for debugging
        FROM assoc.AssociationBalances
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        -- 2. Fallback to live calculation if snapshot not yet generated
        EXEC assoc.sp_Finance_GetAssociationSummary @AssociationId, @TenantId;
    END
END
GO
