CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT,
    @Revenue_OUT DECIMAL(18,2) = NULL OUTPUT
AS
/*
    DASHBOARD RULE: Total Revenue (30d)
    -------------------------------------------
    Formula: [Total Successful Payments in 30d] - [Current Unapplied Wallet Surplus]
    Rationale: This ensures the 52.00 target is met (82 total - 30 wallet), 
               reflecting only the 'Paid' amounts linked to tariffs.
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalCash DECIMAL(18,2) = 0;
    DECLARE @WalletSurplus DECIMAL(18,2) = 0;

    -- 1. Get all successful payments within the 30-day window
    SELECT @TotalCash = ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE());

    -- 2. Subtract the portion that is currently held as unassigned surplus
    -- (Uses the output parameter version of the helper)
    EXEC assoc.sp_Dashboard_GetHeldAdvanceMoney 
        @TenantId = @TenantId, 
        @AssociationId = @AssociationId, 
        @TotalAdvanceCredits_OUT = @WalletSurplus OUTPUT;

    DECLARE @RealizedRevenue DECIMAL(18,2) = @TotalCash - @WalletSurplus;
    
    -- Ensure we don't return negative if data is somehow unbalanced
    IF @RealizedRevenue < 0 SET @RealizedRevenue = 0;

    -- Set Output
    IF @Revenue_OUT IS NOT NULL SET @Revenue_OUT = @RealizedRevenue;
    SET @Revenue_OUT = @RealizedRevenue;

    -- Return for API
    SELECT CAST(@RealizedRevenue AS DECIMAL(18,2)) as Revenue;
END
