CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Enhanced NetDue Calculation (Dynamic Fines + Partial Payments)
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate
    FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;

    WITH InvoiceData AS (
        SELECT 
            i.InvoiceId, i.DueDate, i.CreatedDate, i.Amount, i.[Status],
            ISNULL(items.TotalLineItems, 0) as TotalLineItems,
            ISNULL(items.PenaltyLineItems, 0) as PenaltyLineItems,
            ISNULL(payments.TotalPaid, 0) as TotalPaid
        FROM assoc.Invoices i WITH (NOLOCK)
        OUTER APPLY (
            SELECT 
                SUM(li.Amount) as TotalLineItems,
                SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%' THEN li.Amount ELSE 0 END) as PenaltyLineItems
            FROM assoc.InvoiceLineItems li WITH (NOLOCK)
            WHERE li.InvoiceId = i.InvoiceId 
        ) items
        OUTER APPLY (
            SELECT SUM(p.Amount) as TotalPaid FROM assoc.Payments p WITH (NOLOCK)
            WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')
        ) payments
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
        AND i.[Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT 
            d.*,
            -- Robust Base Amount: MAX of the recorded Amount or sum of all line items
            CASE WHEN d.Amount > d.TotalLineItems THEN d.Amount ELSE d.TotalLineItems END as GrossBilled,
            CASE 
                WHEN d.DueDate >= GETUTCDATE() THEN 0
                WHEN @StrategyType IS NULL OR @StrategyType = 'None' THEN 0
                WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0
                WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= @GracePeriodDays THEN 0
                WHEN d.PenaltyLineItems > 0 THEN 0 
                ELSE 
                    (SELECT 
                        CASE 
                            WHEN @StrategyType = 'FlatAmount' THEN @FineValue * monthsLate
                            WHEN @StrategyType = 'OneTimeFlat' THEN @FineValue
                            WHEN @StrategyType = 'OneTimePercentage' THEN ROUND(d.Amount * (@FineValue / 100.0), 2)
                            WHEN @StrategyType = 'Percentage' AND @IsCompounding = 0 THEN ROUND(d.Amount * (@FineValue / 100.0) * monthsLate, 2)
                            WHEN @StrategyType = 'Percentage' AND @IsCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (@FineValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2)
                            ELSE 0
                        END
                     FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m
                    )
            END as DynamicFine
        FROM InvoiceData d
    )
    SELECT CAST(ISNULL(SUM((GrossBilled + DynamicFine) - TotalPaid), 0) AS DECIMAL(18,2))
    FROM CalculatedFines
    WHERE (GrossBilled + DynamicFine) - TotalPaid > 0;
END
GO