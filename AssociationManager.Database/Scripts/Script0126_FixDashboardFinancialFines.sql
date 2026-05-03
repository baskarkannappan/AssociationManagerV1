PRINT 'Deploying Dashboard Financial Fixes (Fines, Revenue, Committee Status)...'
GO

-- 1. Fix Association Balances Sync
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
            ISNULL(payments.TotalPaid, 0) as TotalPaid,
            -- Prioritize Invoice-level fine rules (Rule Snapshot)
            COALESCE(i.FineStrategy, @StrategyType) as EffectiveStrategy,
            COALESCE(i.FineValue, @FineValue) as EffectiveValue,
            COALESCE(i.FineGracePeriod, @GracePeriodDays) as EffectiveGrace,
            COALESCE(i.FineIsCompounding, @IsCompounding) as EffectiveCompounding
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
            -- Robust Base Amount: Principal + Recorded Extras (avoiding flawed MAX logic)
            CAST(d.Amount + d.PenaltyLineItems AS DECIMAL(18,2)) as GrossBilled,
            CASE 
                WHEN d.DueDate >= GETUTCDATE() THEN 0
                WHEN d.EffectiveStrategy IS NULL OR d.EffectiveStrategy = 'None' THEN 0
                WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0
                WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= d.EffectiveGrace THEN 0
                WHEN d.PenaltyLineItems > 0 THEN 0 -- Skip dynamic calculation if penalty is already posted
                ELSE 
                    (SELECT 
                        CASE 
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
GO

-- 2. Fix Net Outstanding Dashboard Proc
CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT, @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StrategyType NVARCHAR(50), @FineValue DECIMAL(18,2), @GracePeriodDays INT, @IsCompounding BIT, @ActivationDate DATETIME;
    SELECT TOP 1 @StrategyType = StrategyType, @FineValue = FineValue, @GracePeriodDays = GracePeriodDays, @IsCompounding = IsCompounding, @ActivationDate = ActivationDate FROM assoc.FineSettings WHERE AssociationId = @AssociationId AND TenantId = @TenantId;
    WITH InvoiceData AS (
        SELECT i.InvoiceId, i.DueDate, i.CreatedDate, i.Amount, i.[Status], ISNULL(items.TotalLineItems, 0) as TotalLineItems, ISNULL(items.PenaltyLineItems, 0) as PenaltyLineItems, ISNULL(payments.TotalPaid, 0) as TotalPaid, COALESCE(i.FineStrategy, @StrategyType) as EffectiveStrategy, COALESCE(i.FineValue, @FineValue) as EffectiveValue, COALESCE(i.FineGracePeriod, @GracePeriodDays) as EffectiveGrace, COALESCE(i.FineIsCompounding, @IsCompounding) as EffectiveCompounding
        FROM assoc.Invoices i WITH (NOLOCK)
        OUTER APPLY (SELECT SUM(li.Amount) as TotalLineItems, SUM(CASE WHEN li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%' THEN li.Amount ELSE 0 END) as PenaltyLineItems FROM assoc.InvoiceLineItems li WITH (NOLOCK) WHERE li.InvoiceId = i.InvoiceId ) items
        OUTER APPLY (SELECT SUM(p.Amount) as TotalPaid FROM assoc.Payments p WITH (NOLOCK) WHERE p.InvoiceId = i.InvoiceId AND p.Status IN ('Paid', 'Completed', 'Captured')) payments
        WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId AND i.[Status] NOT IN ('Paid', 'Cancelled', 'Void', 'Draft')
    ),
    CalculatedFines AS (
        SELECT d.*, CAST(d.Amount + d.PenaltyLineItems AS DECIMAL(18,2)) as GrossBilled,
            CASE WHEN d.DueDate >= GETUTCDATE() THEN 0 WHEN d.EffectiveStrategy IS NULL OR d.EffectiveStrategy = 'None' THEN 0 WHEN @ActivationDate IS NULL OR d.CreatedDate < @ActivationDate THEN 0 WHEN DATEDIFF(DAY, d.DueDate, GETUTCDATE()) <= d.EffectiveGrace THEN 0 WHEN d.PenaltyLineItems > 0 THEN 0 ELSE 
                (SELECT CASE WHEN d.EffectiveStrategy = 'FlatAmount' THEN d.EffectiveValue * monthsLate WHEN d.EffectiveStrategy = 'OneTimeFlat' THEN d.EffectiveValue WHEN d.EffectiveStrategy = 'OneTimePercentage' THEN ROUND(d.Amount * (d.EffectiveValue / 100.0), 2) WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 0 THEN ROUND(d.Amount * (d.EffectiveValue / 100.0) * monthsLate, 2) WHEN d.EffectiveStrategy = 'Percentage' AND d.EffectiveCompounding = 1 THEN ROUND(d.Amount * (POWER(CAST(1 + (d.EffectiveValue / 100.0) AS FLOAT), monthsLate)) - d.Amount, 2) ELSE 0 END FROM (SELECT CEILING(DATEDIFF(DAY, d.DueDate, GETUTCDATE()) / 30.44) as monthsLate) m)
            END as DynamicFine FROM InvoiceData d
    )
    SELECT CAST(ISNULL(SUM((GrossBilled + DynamicFine) - TotalPaid), 0) AS DECIMAL(18,2)) FROM CalculatedFines WHERE (GrossBilled + DynamicFine) - TotalPaid > 0;
END
GO

-- 3. Fix Invoices GetPaged Summary
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @AssetId INT = NULL,
    @AssetIds NVARCHAR(MAX) = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'CreatedDate',
    @SortDirection NVARCHAR(10) = 'DESC',
    @IncludeDraft BIT = 0,
    @ReferenceId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    IF @SortColumn NOT IN ('Title', 'Amount', 'DueDate', 'Status', 'CreatedDate', 'AssetName') SET @SortColumn = 'CreatedDate';
    IF @SortDirection NOT IN ('ASC', 'DESC') SET @SortDirection = 'DESC';

    ;WITH FilteredInvoices AS (
        SELECT 
            i.InvoiceId, i.TenantId, i.AssociationId, i.AssetId, i.BillingBatchId, i.Title, i.Description, 
            i.Amount, i.IsAdvancePaid,
            i.DueDate, i.Status, i.CreatedDate,
            a.Name AS AssetName,
            CAST(COUNT(*) OVER() AS INT) as TotalCount,
            CAST(SUM(CASE WHEN i.Status NOT IN ('Paid', 'Cancelled', 'Void', 'Draft') THEN (i.Amount + ISNULL(fines.TotalFines, 0)) ELSE 0 END) OVER() AS DECIMAL(18,2)) as TotalUnpaid
        FROM assoc.Invoices i WITH (NOLOCK)
        LEFT JOIN assoc.Assets a WITH (NOLOCK) ON i.AssetId = a.AssetId
        OUTER APPLY (
            SELECT SUM(li.Amount) as TotalFines 
            FROM assoc.InvoiceLineItems li WITH (NOLOCK) 
            WHERE li.InvoiceId = i.InvoiceId 
            AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%')
        ) fines
        WHERE i.TenantId = @TenantId
        AND (@AssociationId IS NULL OR i.AssociationId = @AssociationId)
        AND (@AssetId IS NULL OR i.AssetId = @AssetId)
        AND (@AssetIds IS NULL OR i.AssetId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@AssetIds, ',')))
        AND (@Status IS NULL OR i.Status = @Status)
        AND (@IncludeDraft = 1 OR i.Status NOT IN ('Draft', 'Error'))
        AND (@SearchTerm IS NULL OR i.Title LIKE '%' + @SearchTerm + '%' OR a.Name LIKE '%' + @SearchTerm + '%')
        AND (@StartDate IS NULL OR i.CreatedDate >= @StartDate)
        AND (@EndDate IS NULL OR i.CreatedDate <= @EndDate)
        AND (@ReferenceId IS NULL OR (@SortDirection = 'DESC' AND i.InvoiceId < @ReferenceId) OR (@SortDirection = 'ASC' AND i.InvoiceId > @ReferenceId))
    )
    SELECT * FROM FilteredInvoices
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN CASE WHEN @SortColumn = 'Title' THEN Title WHEN @SortColumn = 'Status' THEN Status WHEN @SortColumn = 'AssetName' THEN AssetName END END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN CASE WHEN @SortColumn = 'Title' THEN Title WHEN @SortColumn = 'Status' THEN Status WHEN @SortColumn = 'AssetName' THEN AssetName END END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN CASE WHEN @SortColumn = 'Amount' THEN Amount WHEN @SortColumn = 'DueDate' THEN CAST(DueDate AS SQL_VARIANT) WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT) END END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN CASE WHEN @SortColumn = 'Amount' THEN Amount WHEN @SortColumn = 'DueDate' THEN CAST(DueDate AS SQL_VARIANT) WHEN @SortColumn = 'CreatedDate' THEN CAST(CreatedDate AS SQL_VARIANT) END END DESC
    OFFSET (CASE WHEN @ReferenceId IS NOT NULL THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT @PageSize ROWS ONLY
    OPTION (RECOMPILE); 
END
GO

-- 4. Fix Committee Count
CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetCommitteeCount
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) 
    FROM assoc.CommitteeMembers 
    WHERE AssociationId = @AssociationId AND IsActive = 1;
END
GO

-- 5. Fix Revenue 30D
CREATE OR ALTER PROCEDURE assoc.sp_Dashboard_GetRevenue30D
    @TenantId INT,
    @AssociationId INT,
    @Revenue_OUT DECIMAL(18,2) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalCash DECIMAL(18,2) = 0;
    SELECT @TotalCash = ISNULL(SUM(Amount), 0) FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Paid', 'Completed', 'Captured') AND CreatedDate >= DATEADD(DAY, -30, GETDATE());
    IF @Revenue_OUT IS NOT NULL SET @Revenue_OUT = @TotalCash;
    SET @Revenue_OUT = @TotalCash;
    SELECT CAST(@TotalCash AS DECIMAL(18,2)) as Revenue;
END
GO

-- 5a. Fix Live Association Summary
CREATE OR ALTER PROCEDURE assoc.sp_Finance_GetAssociationSummary
    @AssociationId INT,
    @TenantId INT,
    @TotalOutstanding_OUT DECIMAL(18,2) = NULL OUTPUT,
    @TotalAdvanceCredits_OUT DECIMAL(18,2) = NULL OUTPUT,
    @UnitsWithCredit_OUT INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalOutstanding DECIMAL(18,2) = 0;
    SELECT @TotalOutstanding = ISNULL(SUM(Amount), 0) FROM assoc.Invoices WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND Status IN ('Unpaid', 'Partial') AND Status NOT IN ('Draft', 'Cancelled', 'Void');
    SELECT @TotalOutstanding = @TotalOutstanding + ISNULL(SUM(li.Amount), 0) FROM assoc.InvoiceLineItems li INNER JOIN assoc.Invoices i ON i.InvoiceId = li.InvoiceId WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId AND i.Status IN ('Unpaid', 'Partial') AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%' OR li.ChargeName LIKE '%Late%' OR li.ChargeName LIKE '%Interest%');
    DECLARE @TotalAdvanceCredits DECIMAL(18,2) = 0;
    DECLARE @UnitsWithCredit INT = 0;
    WITH WalletBalances AS (SELECT AssetId, SUM(CASE WHEN Type = 'Credit' AND (Category = 'Payment' OR Category = 'Advance Payment') AND (InvoiceId IS NULL OR InvoiceId = 0) THEN Amount ELSE 0 END) - SUM(CASE WHEN Type = 'Debit' AND (Category = 'Credit Settlement' OR Category = 'Internal Credit Transfer') THEN Amount ELSE 0 END) as Balance FROM assoc.Transactions WHERE TenantId = @TenantId AND AssociationId = @AssociationId GROUP BY AssetId)
    SELECT @TotalAdvanceCredits = ISNULL(SUM(Balance), 0), @UnitsWithCredit = COUNT(*) FROM WalletBalances WHERE Balance > 0;
    IF @TotalOutstanding_OUT IS NOT NULL SET @TotalOutstanding_OUT = @TotalOutstanding;
    IF @TotalAdvanceCredits_OUT IS NOT NULL SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    IF @UnitsWithCredit_OUT IS NOT NULL SET @UnitsWithCredit_OUT = @UnitsWithCredit;
    SET @TotalOutstanding_OUT = @TotalOutstanding;
    SET @TotalAdvanceCredits_OUT = @TotalAdvanceCredits;
    SET @UnitsWithCredit_OUT = @UnitsWithCredit;
    SELECT CAST(ISNULL(@TotalOutstanding, 0) AS DECIMAL(18,2)) as TotalOutstanding, CAST(ISNULL(@TotalAdvanceCredits, 0) AS DECIMAL(18,2)) as TotalAdvanceCredits, ISNULL(@UnitsWithCredit, 0) as UnitsWithCredit;
END
GO

-- 6. TRIGGER IMMEDIATE SYNC FOR ALL ASSOCIATIONS
PRINT 'Triggering immediate balance sync for all associations...'
DECLARE @AssocId INT;
DECLARE AssocCursor CURSOR FOR SELECT AssociationId FROM corp.Associations;
OPEN AssocCursor;
FETCH NEXT FROM AssocCursor INTO @AssocId;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC assoc.sp_AssociationBalances_Sync @AssociationId = @AssocId;
    FETCH NEXT FROM AssocCursor INTO @AssocId;
END
CLOSE AssocCursor;
DEALLOCATE AssocCursor;
GO

PRINT 'Deployment complete.'
