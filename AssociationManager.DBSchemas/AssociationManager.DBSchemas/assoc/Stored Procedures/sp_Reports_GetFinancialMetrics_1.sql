CREATE PROCEDURE assoc.sp_Reports_GetFinancialMetrics
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Aging Calculation
    ;WITH UnpaidInvoices AS (
        SELECT 
            i.InvoiceId,
            i.DueDate,
            i.Amount + ISNULL(fines.TotalFines, 0) as TotalDue
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    )
    SELECT 
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 0 AND 30 THEN TotalDue ELSE 0 END) AS Bucket0_30,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 31 AND 60 THEN TotalDue ELSE 0 END) AS Bucket31_60,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) BETWEEN 61 AND 90 THEN TotalDue ELSE 0 END) AS Bucket61_90,
        SUM(CASE WHEN DATEDIFF(day, DueDate, GETUTCDATE()) > 90 THEN TotalDue ELSE 0 END) AS BucketOver90
    FROM UnpaidInvoices;

    -- 2. Monthly Collection Efficiency
    ;WITH Months AS (
        SELECT TOP 6 
            FORMAT(DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE()), 'MMM yyyy') AS MonthLabel,
            DATEPART(MONTH, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Month],
            DATEPART(YEAR, DATEADD(MONTH, - (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1), GETUTCDATE())) AS [Year]
        FROM sys.objects
    ),
    MonthlyBilled AS (
        SELECT 
            DATEPART(MONTH, i.CreatedDate) as [Month],
            DATEPART(YEAR, i.CreatedDate) as [Year],
            SUM(i.Amount + ISNULL(fines.TotalFines, 0)) as TotalBilled
        FROM assoc.Invoices i
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')
        ) fines
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.Status != 'Draft'
        GROUP BY DATEPART(MONTH, i.CreatedDate), DATEPART(YEAR, i.CreatedDate)
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
        (SELECT ISNULL(SUM(Amount), 0) FROM assoc.Invoices WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status NOT IN ('Paid', 'Cancelled', 'Draft')) as TotalUnpaidPrincipal
END;