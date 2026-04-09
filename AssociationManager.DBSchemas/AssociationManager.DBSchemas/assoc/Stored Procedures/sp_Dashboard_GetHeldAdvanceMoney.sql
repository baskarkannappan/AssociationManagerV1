CREATE PROCEDURE assoc.sp_Dashboard_GetHeldAdvanceMoney
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate wallet balance per unit
    -- Credits (Advances) - Debits (Settlements)
    WITH UnitBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT 
        ISNULL(SUM(Balance), 0) as TotalAdvanceCredits,
        COUNT(CASE WHEN Balance > 0 THEN 1 END) as UnitsWithCredit
    FROM UnitBalances
    WHERE Balance > 0;
END
