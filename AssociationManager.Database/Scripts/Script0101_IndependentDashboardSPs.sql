-- Script0101_IndependentDashboardSPs.sql
-- Independent Stored Procedures for Dashboard Metrics

-- 1. Total Members
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Dashboard_GetTotalMembers]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Dashboard_GetTotalMembers];
GO
CREATE PROCEDURE assoc.sp_Dashboard_GetTotalMembers
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(DISTINCT PersonId) 
    FROM assoc.Occupancy 
    WHERE TenantId = @TenantId AND AssociationId = @AssociationId;
END
GO

-- 2. Committee Count
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Dashboard_GetCommitteeCount]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Dashboard_GetCommitteeCount];
GO
CREATE PROCEDURE assoc.sp_Dashboard_GetCommitteeCount
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) 
    FROM assoc.CommitteeMembers 
    WHERE AssociationId = @AssociationId;
END
GO

-- 3. Revenue (30 Days)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Dashboard_GetRevenue30D]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Dashboard_GetRevenue30D];
GO
CREATE PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ISNULL(SUM(Amount), 0) 
    FROM assoc.Payments 
    WHERE TenantId = @TenantId 
    AND AssociationId = @AssociationId 
    AND Status IN ('Paid', 'Completed', 'Captured')
    AND CreatedDate >= DATEADD(DAY, -30, GETDATE())
    AND (Notes IS NULL OR Notes NOT LIKE 'Auto-Settled%');
END
GO

-- 4. Net Outstanding
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Dashboard_GetNetOutstanding]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Dashboard_GetNetOutstanding];
GO
CREATE PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ISNULL(SUM(TotalDue), 0)
    FROM (
        SELECT 
            i.InvoiceId,
            i.Amount + ISNULL((SELECT SUM(li.Amount) FROM assoc.InvoiceLineItems li WHERE li.InvoiceId = i.InvoiceId AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')), 0) as TotalDue
        FROM assoc.Invoices i
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void')
    ) as UnpaidTotals;
END
GO

-- 5. Held Advance Money
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Dashboard_GetHeldAdvanceMoney]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Dashboard_GetHeldAdvanceMoney];
GO
CREATE PROCEDURE assoc.sp_Dashboard_GetHeldAdvanceMoney
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
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
GO
