CREATE   PROCEDURE assoc.sp_AssociationBalances_Sync 
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

    -- Enhanced Outstanding Calculation (matches v2 reporting logic)
    -- Includes: Principal + Recorded Fines + Dynamic (Unposted) Fines - Total Paid
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    
    SELECT TOP 1 
        @StrategyType = StrategyType,
        @FineValue = FineValue,
        @GracePeriodDays = GracePeriodDays,
        @IsCompounding = IsCompounding,
        @ActivationDate = ActivationDate
    FROM assoc.FineSettings
    WHERE AssociationId = @AssociationId AND TenantId = @RealTenantId;

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
            SELECT SUM(p.Amount) as TotalPaid
            FROM assoc.Payments p WITH (NOLOCK)
            WHERE p.InvoiceId = i.InvoiceId
            AND p.Status IN ('Paid', 'Completed', 'Captured')
        ) payments
        WHERE i.TenantId = @RealTenantId AND i.AssociationId = @AssociationId
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
                WHEN d.PenaltyLineItems > 0 THEN 0 -- Skip dynamic calculation if penalty is already posted
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
    SELECT @LiveOutstanding = ISNULL(SUM(CAST((GrossBilled + DynamicFine) - TotalPaid AS DECIMAL(18,2))), 0)
    FROM CalculatedFines
    WHERE (GrossBilled + DynamicFine) - TotalPaid > 0;
    
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