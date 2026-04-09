-- Script0104_FinancialReportingProcedures.sql
-- Adds stored procedures for advanced financial reporting and collection analytics

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Reports_GetFinancialMetrics]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Reports_GetFinancialMetrics];
GO

CREATE PROCEDURE assoc.sp_Reports_GetFinancialMetrics
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Aging Calculation
    ;WITH InvoiceFines AS (
        SELECT li.InvoiceId, SUM(li.Amount) as TotalFines
        FROM assoc.InvoiceLineItems li
        WHERE li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%'
        GROUP BY li.InvoiceId
    ),
    UnpaidInvoices AS (
        SELECT 
            i.InvoiceId,
            i.DueDate,
            i.Amount + ISNULL(f.TotalFines, 0) as TotalDue
        FROM assoc.Invoices i
        LEFT JOIN InvoiceFines f ON i.InvoiceId = f.InvoiceId
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void')
    )
    SELECT 
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) <= 30 THEN TotalDue ELSE 0 END), 0) AS Bucket0_30,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 31 AND 60 THEN TotalDue ELSE 0 END), 0) AS Bucket31_60,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 61 AND 90 THEN TotalDue ELSE 0 END), 0) AS Bucket61_90,
        ISNULL(SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) > 90 THEN TotalDue ELSE 0 END), 0) AS BucketOver90
    FROM UnpaidInvoices;

    -- 2. Monthly Collection Efficiency
    ;WITH Months AS (
        SELECT TOP 6 
            FORMAT(DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE()), 'MMM yyyy') AS MonthLabel,
            DATEPART(MONTH, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Month],
            DATEPART(YEAR, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Year]
        FROM sys.objects
    ),
    InvoiceFinesGlobal AS (
        SELECT li.InvoiceId, SUM(li.Amount) as TotalFines
        FROM assoc.InvoiceLineItems li
        WHERE li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%'
        GROUP BY li.InvoiceId
    ),
    MonthlyBilled AS (
        SELECT 
            DATEPART(MONTH, CreatedDate) as [Month],
            DATEPART(YEAR, CreatedDate) as [Year],
            SUM(i.Amount + ISNULL(f.TotalFines, 0)) as TotalBilled
        FROM assoc.Invoices i
        LEFT JOIN InvoiceFinesGlobal f ON i.InvoiceId = f.InvoiceId
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        GROUP BY DATEPART(MONTH, CreatedDate), DATEPART(YEAR, CreatedDate)
    ),
    MonthlyCollected AS (
        SELECT 
            DATEPART(MONTH, i.CreatedDate) as [Month],
            DATEPART(YEAR, i.CreatedDate) as [Year],
            SUM(p.Amount) as TotalCollected
        FROM assoc.Payments p
        INNER JOIN assoc.Invoices i ON p.InvoiceId = i.InvoiceId
        WHERE p.TenantId = @TenantId AND p.AssociationId = @AssociationId
        AND p.Status IN ('Paid', 'Completed', 'Captured')
        GROUP BY DATEPART(MONTH, i.CreatedDate), DATEPART(YEAR, i.CreatedDate)
    )
    SELECT 
        m.MonthLabel as [Month],
        ISNULL(mb.TotalBilled, 0) as BilledAmount,
        ISNULL(mc.TotalCollected, 0) as CollectedAmount
    FROM Months m
    LEFT JOIN MonthlyBilled mb ON m.[Month] = mb.[Month] AND m.[Year] = mb.[Year]
    LEFT JOIN MonthlyCollected mc ON m.[Month] = mc.[Month] AND m.[Year] = mc.[Year]
    ORDER BY m.[Year] ASC, m.[Month] ASC;

    -- 3. High Level Stats
    SELECT 
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured')) as TotalCollectedAllTime,
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Invoices WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status NOT IN ('Paid', 'Cancelled')) as TotalUnpaidPrincipal
END
GO
