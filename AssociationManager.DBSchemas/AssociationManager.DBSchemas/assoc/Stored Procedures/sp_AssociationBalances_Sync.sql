-- 1. Fix Association Balances Sync
CREATE OR ALTER   PROCEDURE assoc.sp_AssociationBalances_Sync 
    @TenantId INT = NULL, 
    @AssociationId INT 
AS 
BEGIN 
    SET NOCOUNT ON; 
    -- Ensure system context for RLS bypass if needed
    EXEC sp_set_session_context @key=N'IsAdmin', @value=1; 
    
    DECLARE @RealTenantId INT = @TenantId; 
    IF @RealTenantId IS NULL
    BEGIN
        SELECT @RealTenantId = TenantId FROM corp.Associations WHERE AssociationId = @AssociationId; 
    END

    IF @RealTenantId IS NULL RETURN; 
    
    DECLARE @LiveOutstanding DECIMAL(18,2) = 0; 
    DECLARE @LiveCredits DECIMAL(18,2) = 0; 
    DECLARE @LiveUnitsWithCredit INT = 0; 
    DECLARE @LiveMembers INT = 0; 
    DECLARE @LiveCommittee INT = 0; 
    DECLARE @LiveRevenue30D DECIMAL(18,2) = 0; 
    DECLARE @PendingWorkOrders INT = 0; 

    -- 2. Enhanced Outstanding & Wallet Calculation (Optimized via Snapshot)
    SELECT 
        @LiveOutstanding = ISNULL(SUM(CASE WHEN OutstandingAmount > PaidAmount THEN OutstandingAmount - PaidAmount ELSE 0 END), 0),
        @LiveCredits = ISNULL(SUM(AdvanceBalance), 0),
        @LiveUnitsWithCredit = COUNT(CASE WHEN AdvanceBalance > 0 THEN 1 END)
    FROM assoc.AssetBalancesSnapshot
    WHERE AssociationId = @AssociationId AND TenantId = @RealTenantId;
    
    -- 4. Other Dashboard Metrics
    SELECT @LiveMembers = COUNT(DISTINCT PersonId) 
    FROM assoc.Occupancy WITH (NOLOCK) 
    WHERE TenantId = @RealTenantId AND AssociationId = @AssociationId; 
    SELECT @LiveCommittee = COUNT(*) 
    FROM assoc.CommitteeMembers WITH (NOLOCK) 
    WHERE AssociationId = @AssociationId AND IsActive = 1; 
    
    SELECT @LiveRevenue30D = ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments WITH (NOLOCK) 
    WHERE TenantId = @RealTenantId AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured') 
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE()); 
    
    SELECT @PendingWorkOrders = COUNT(*) 
    FROM assoc.WorkOrders WITH (NOLOCK) 
    WHERE TenantId = @RealTenantId AND AssociationId = @AssociationId 
    AND Status NOT IN ('Completed', 'Closed'); 
    
    -- 5. Upsert into Snapshot Table
    IF EXISTS (SELECT 1 FROM assoc.AssociationBalances WHERE AssociationId = @AssociationId) 
    BEGIN 
        UPDATE assoc.AssociationBalances 
        SET 
            TenantId = @RealTenantId, 
            TotalOutstanding = @LiveOutstanding, 
            TotalAdvanceCredits = @LiveCredits, 
            UnitsWithCredit = @LiveUnitsWithCredit, 
            TotalMembers = @LiveMembers, 
            CommitteeMembers = @LiveCommittee, 
            TotalRevenue = @LiveRevenue30D, 
            PendingWorkOrders = @PendingWorkOrders, 
            LastUpdated = GETDATE() 
        WHERE AssociationId = @AssociationId; 
    END 
    ELSE 
    BEGIN 
        INSERT INTO assoc.AssociationBalances (AssociationId, TenantId, TotalOutstanding, TotalAdvanceCredits, UnitsWithCredit, TotalMembers, CommitteeMembers, TotalRevenue, PendingWorkOrders, LastUpdated) 
        VALUES (@AssociationId, @RealTenantId, @LiveOutstanding, @LiveCredits, @LiveUnitsWithCredit, @LiveMembers, @LiveCommittee, @LiveRevenue30D, @PendingWorkOrders, GETDATE()); 
    END 
END