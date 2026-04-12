-- Script0116_OptimizeAssociationSummary.sql
-- Optimized version of sp_Finance_GetAssociationSummary to handle association-level metrics in a single pass.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Using a CTE for better readability and potential optimizer benefits
    WITH AssetBalances AS (
        SELECT 
            AssetId, 
            ISNULL(SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END), 0) as NetBalance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId 
          AND (@AssociationId = 0 OR AssociationId = @AssociationId)
          AND Category != 'Credit Settlement' -- Exclude internal settlements to avoid double counting
        GROUP BY AssetId
    )
    SELECT 
        CAST(ISNULL(SUM(CASE WHEN NetBalance > 0 THEN NetBalance ELSE 0 END), 0) AS DECIMAL(18,2)) as TotalOutstanding,
        CAST(ISNULL(SUM(CASE WHEN NetBalance < 0 THEN ABS(NetBalance) ELSE 0 END), 0) AS DECIMAL(18,2)) as TotalAdvanceCredits,
        CAST(COUNT(CASE WHEN NetBalance < 0 THEN 1 END) AS INT) as UnitsWithCredit
    FROM AssetBalances;
END
GO
