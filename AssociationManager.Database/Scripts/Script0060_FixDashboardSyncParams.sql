-- Script0060_FixDashboardSyncParams.sql
-- Goal: Fix SqlException by making @TenantId optional in sp_AssociationBalances_Sync
-- This ensures database triggers (which only pass @AssociationId) continue to work.

PRINT 'Redefining assoc.sp_AssociationBalances_Sync to make @TenantId optional...';
GO

CREATE OR ALTER PROCEDURE assoc.sp_AssociationBalances_Sync 
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
    
    -- 1. Principal (Uses IX_Invoices_Summary index)
    SELECT @LiveOutstanding = ISNULL(SUM(Amount), 0) 
    FROM assoc.Invoices WITH (NOLOCK) 
    WHERE TenantId = @RealTenantId AND AssociationId = @AssociationId 
    AND Status IN ('Unpaid', 'Partial'); 
    
    -- 2. Penalties/Fines (Uses IX_InvoiceLineItems_InvoiceId index)
    SELECT @LiveOutstanding = @LiveOutstanding + ISNULL(SUM(li.Amount), 0) 
    FROM assoc.InvoiceLineItems li WITH (NOLOCK) 
    INNER JOIN assoc.Invoices i ON i.InvoiceId = li.InvoiceId 
    WHERE i.TenantId = @RealTenantId AND i.AssociationId = @AssociationId 
    AND i.Status IN ('Unpaid', 'Partial') 
    AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%'); 
    
    -- 3. Wallet Balances/Credits
    WITH WalletBalances AS ( 
        SELECT 
            AssetId, 
            SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) - 
            SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance 
        FROM assoc.Transactions WITH (NOLOCK) 
        WHERE TenantId = @RealTenantId AND AssociationId = @AssociationId 
        GROUP BY AssetId 
    ) 
    SELECT @LiveCredits = ISNULL(SUM(Balance), 0), @LiveUnitsWithCredit = COUNT(*) 
    FROM WalletBalances 
    WHERE Balance > 0; 
    
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
GO

PRINT 'Script0060 completed successfully.';
