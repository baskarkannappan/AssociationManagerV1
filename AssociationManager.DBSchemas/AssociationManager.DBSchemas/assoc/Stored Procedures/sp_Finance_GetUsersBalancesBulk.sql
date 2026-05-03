CREATE PROCEDURE assoc.sp_Finance_GetUsersBalancesBulk
    @AssociationId INT,
    @UserIds NVARCHAR(MAX) -- Comma-separated list of UserIds
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Parse UserIds into a table variable
    DECLARE @UserList TABLE (UserId INT PRIMARY KEY);
    INSERT INTO @UserList (UserId)
    SELECT CAST(value AS INT) FROM STRING_SPLIT(@UserIds, ',');

    -- 2. Resolve all Assets for these Users
    -- We need this to calculate credits (which are often tied to assets)
    DECLARE @UserAssets TABLE (UserId INT, AssetId INT, PRIMARY KEY (UserId, AssetId));
    INSERT INTO @UserAssets (UserId, AssetId)
    SELECT DISTINCT u.UserId, o.AssetId
    FROM assoc.Users u
    INNER JOIN @UserList ul ON u.UserId = ul.UserId
    INNER JOIN assoc.Persons p ON u.Email = p.Email
    INNER JOIN assoc.Occupancy o ON p.PersonId = o.PersonId
    WHERE o.AssociationId = @AssociationId;

    -- 3. Get Fine Settings
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate 
    FROM assoc.FineSettings 
    WHERE AssociationId = @AssociationId;

    -- 4. Calculate Unpaid Invoices (including Dynamic Fines)
    -- This CTE logic is adapted from sp_Finance_GetSummaryStats but grouped by UserId
    WITH InvoiceData AS (
        SELECT 
            ua.UserId,
            i.InvoiceId, i.DueDate, i.CreatedDate, i.Amount,
            ISNULL(items.TotalLineItems, 0) as TotalLineItems, 
            ISNULL(items.PenaltyLineItems, 0) as PenaltyLineItems, 
            ISNULL(payments.TotalPaid, 0) as TotalPaid, 
            COALESCE(i.FineStrategy, @StrategyType) as EffectiveStrategy, 
            COALESCE(i.FineValue, @FineValue) as EffectiveValue, 
            COALESCE(i.FineGracePeriod, @GracePeriodDays) as EffectiveGrace, 
            COALESCE(i.FineIsCompounding, @IsCompounding) as EffectiveCompounding
        FROM assoc.Invoices i WITH (NOLOCK)
        INNER JOIN @UserAssets ua ON i.AssetId = ua.AssetId
        OUTER APPLY (
            SELECT 
                SUM(li.Amount) as TotalLineItems, 
                SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%' THEN li.Amount ELSE 0 END) as PenaltyLineItems 
            FROM assoc.InvoiceLineItems li WITH (NOLOCK) 
            WHERE li.InvoiceId = i.InvoiceId 
        ) items
        OUTER APPLY (
            SELECT SUM(p.Amount) as TotalPaid 
            FROM assoc.Payments p WITH (NOLOCK) 
            WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')
        ) payments
        WHERE i.AssociationId = @AssociationId 
        AND i.[Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT 
            d.*, 
            CASE WHEN d.Amount > d.TotalLineItems THEN d.Amount ELSE d.TotalLineItems END as GrossBilled,
            CASE 
                WHEN d.DueDate >= GETUTCDATE() THEN 0 
                WHEN d.EffectiveStrategy IS NULL OR d.EffectiveStrategy = 'None' THEN 0 
                WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0 
                WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= d.EffectiveGrace THEN 0 
                WHEN d.PenaltyLineItems > 0 THEN 0 
                ELSE 
                (
                    SELECT CASE 
                        WHEN d.EffectiveStrategy = 'FlatAmount' THEN d.EffectiveValue * monthsLate 
                        WHEN d.EffectiveStrategy = 'OneTimeFlat' THEN d.EffectiveValue 
                        WHEN d.EffectiveStrategy = 'OneTimePercentage' THEN ROUND(d.Amount * (d.EffectiveValue / 100.0), 2) 
                        WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 0 THEN ROUND(d.Amount * (d.EffectiveValue / 100.0) * monthsLate, 2) 
                        WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (d.EffectiveValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2) 
                        ELSE 0 
                    END 
                    FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m
                )
            END as DynamicFine 
        FROM InvoiceData d
    ),
    UserUnpaid AS (
        SELECT 
            UserId,
            ISNULL(SUM(CAST((GrossBilled + DynamicFine) - TotalPaid AS DECIMAL(18,2))), 0) as TotalUnpaid
        FROM CalculatedFines 
        WHERE (GrossBilled + DynamicFine) - TotalPaid > 0
        GROUP BY UserId
    ),
    -- 5. Calculate Advance Credits (Wallet Balance)
    UserCredits AS (
        SELECT 
            ua.UserId,
            ISNULL(SUM(p.Amount), 0) as TotalCredits
        FROM assoc.Payments p WITH (NOLOCK)
        INNER JOIN @UserAssets ua ON p.AssetId = ua.AssetId
        WHERE p.AssociationId = @AssociationId 
        AND p.InvoiceId IS NULL 
        AND p.Status IN ('Completed', 'Paid')
        GROUP BY ua.UserId
    ),
    UserSettlements AS (
        SELECT 
            ua.UserId,
            ISNULL(SUM(t.Amount), 0) as TotalSettlements
        FROM assoc.Transactions t WITH (NOLOCK)
        INNER JOIN @UserAssets ua ON t.AssetId = ua.AssetId
        WHERE t.AssociationId = @AssociationId 
        AND t.Type = 'Debit' 
        AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer')
        GROUP BY ua.UserId
    )
    -- 6. Final Result
    SELECT 
        ul.UserId,
        ISNULL(uu.TotalUnpaid, 0) as TotalUnpaid,
        ISNULL(uc.TotalCredits, 0) - ISNULL(us.TotalSettlements, 0) as TotalAdvanceCredits
    FROM @UserList ul
    LEFT JOIN UserUnpaid uu ON ul.UserId = uu.UserId
    LEFT JOIN UserCredits uc ON ul.UserId = uc.UserId
    LEFT JOIN UserSettlements us ON ul.UserId = us.UserId;
END
GO
