CREATE   PROCEDURE assoc.sp_Finance_ValidateIntegrity
    @AssociationId INT,
    @TenantId INT,
    @IntegrityStatus_OUT NVARCHAR(50) = NULL OUTPUT
AS
/*
    FINANCIAL GUARDIAN: Integrity Verification
    -------------------------------------------
    This procedure cross-references the Dashboard Summary results against the raw source tables.
    Matches the Simplified (Total - Wallet) Revenue model.
*/
BEGIN
    SET NOCOUNT ON;

    -- 1. Get current reported values from the system
    DECLARE @ReportedOutstanding DECIMAL(18,2);
    DECLARE @ReportedAdvance DECIMAL(18,2);
    DECLARE @ReportedUnits INT;
    DECLARE @ReportedRevenue30D DECIMAL(18,2);
    
    EXEC assoc.sp_Finance_GetAssociationSummary 
        @AssociationId = @AssociationId, 
        @TenantId = @TenantId,
        @TotalOutstanding_OUT = @ReportedOutstanding OUTPUT,
        @TotalAdvanceCredits_OUT = @ReportedAdvance OUTPUT,
        @UnitsWithCredit_OUT = @ReportedUnits OUTPUT;

    EXEC assoc.sp_Dashboard_GetRevenue30D 
        @TenantId = @TenantId, 
        @AssociationId = @AssociationId,
        @Revenue_OUT = @ReportedRevenue30D OUTPUT;

    -- 2. Recalculate EXPECTED values from source tables
    DECLARE @ExpectedOutstanding DECIMAL(18,2);
    DECLARE @ExpectedAdvance DECIMAL(18,2);
    DECLARE @ExpectedRevenue30D DECIMAL(18,2);

    -- Expected Outstanding (Sum of Unpaid Invoices)
    -- This relies on the core Invoice table status.
    SELECT @ExpectedOutstanding = ISNULL(SUM(Amount), 0)
    FROM assoc.Invoices WITH (NOLOCK)
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId
    AND Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft');

    -- Expected Advance (Actual Ledger spendable balance)
    WITH WalletBalances AS (
        SELECT 
            AssetId,
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) -
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance
        FROM assoc.Transactions WITH (NOLOCK)
        WHERE TenantId = @TenantId AND AssociationId = @AssociationId
        GROUP BY AssetId
    )
    SELECT @ExpectedAdvance = ISNULL(SUM(Balance), 0) FROM WalletBalances WHERE Balance > 0;

    -- Expected Revenue 30D (Calculated simply as Total Cash minus current wallet)
    -- This matches the user's manual (22 + 30 = 52) logic exactly.
    DECLARE @Raw30DCash DECIMAL(18,2) = 0;
    SELECT @Raw30DCash = ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments WITH (NOLOCK)
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    SET @ExpectedRevenue30D = @Raw30DCash - @ExpectedAdvance;
    IF @ExpectedRevenue30D < 0 SET @ExpectedRevenue30D = 0;

    -- 3. Calculate Drift
    DECLARE @OutsDrift DECIMAL(18,2) = ABS(@ReportedOutstanding - @ExpectedOutstanding);
    DECLARE @AdvDrift DECIMAL(18,2) = ABS(@ReportedAdvance - @ExpectedAdvance);
    DECLARE @RevDrift DECIMAL(18,2) = ABS(@ReportedRevenue30D - @ExpectedRevenue30D);

    DECLARE @Status NVARCHAR(50) = CASE WHEN @OutsDrift < 0.01 AND @AdvDrift < 0.01 AND @RevDrift < 0.01 THEN 'SUCCESS' ELSE 'FAILURE' END;
    IF @IntegrityStatus_OUT IS NOT NULL SET @IntegrityStatus_OUT = @Status;
    SET @IntegrityStatus_OUT = @Status;

    -- 4. Return Integrity Report
    SELECT 
        @Status as IntegrityStatus,
        @ReportedOutstanding as ReportedOutstanding,
        @ExpectedOutstanding as ExpectedOutstanding,
        @OutsDrift as OutstandingDrift,
        @ReportedAdvance as ReportedAdvance,
        @ExpectedAdvance as ExpectedAdvance,
        @AdvDrift as AdvanceDrift,
        @ReportedRevenue30D as ReportedRevenue30D,
        @ExpectedRevenue30D as ExpectedRevenue30D,
        @RevDrift as RevenueDrift,
        GETUTCDATE() as VerificationTime;
END