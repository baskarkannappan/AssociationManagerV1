-- Script0082_DeduplicateWalletHistory.sql
-- Fix: Deduplicating wallet history by only including 'Debit' transactions from the ledger.
-- This ensures only the money leaving the wallet is visible, excluding the corresponding invoice credit.

CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetAdvancesPaged
    @TenantId INT,
    @AssociationId INT = NULL,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'Date',
    @SortDirection NVARCHAR(10) = 'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Sorting Safety
    IF @SortColumn NOT IN ('ResidentName', 'UnitName', 'Amount', 'Date', 'Status', 'ReferenceId')
        SET @SortColumn = 'Date';
    
    IF @SortDirection NOT IN ('ASC', 'DESC')
        SET @SortDirection = 'DESC';

    -- NEW: Robust Identity Resolution (resolves from either schema)
    DECLARE @UserEmail NVARCHAR(255);
    SELECT @UserEmail = Email FROM corp.Users WHERE UserId = @UserId;
    
    IF @UserEmail IS NULL
        SELECT @UserEmail = Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId;

    -- CTE for Filtering and Paging
    ;WITH RawAdvances AS (
        -- 1. TOP-UPS (Credits)
        SELECT 
            p.Amount,
            p.CreatedDate AS [Date],
            p.Status,
            p.GatewayReference AS ReferenceId,
            u.Name AS ResidentName,
            a.Name AS UnitName,
            p.UserId,
            p.AssetId
        FROM assoc.Payments p
        LEFT JOIN corp.Users cu ON p.UserId = cu.UserId
        LEFT JOIN assoc.Users au ON p.UserId = au.UserId AND p.TenantId = @TenantId
        LEFT JOIN assoc.Users u ON p.UserId = u.UserId AND p.TenantId = @TenantId -- For Display Name
        LEFT JOIN assoc.Assets a ON p.AssetId = a.AssetId
        WHERE p.TenantId = @TenantId
          AND p.InvoiceId IS NULL -- Top-ups / Advances
          AND (@AssociationId IS NULL OR p.AssociationId = @AssociationId)
          -- Match by Email OR UserId for Identity consistency
          AND (
                @UserId IS NULL 
                OR (@UserEmail IS NOT NULL AND (cu.Email = @UserEmail OR au.Email = @UserEmail))
                OR p.UserId = @UserId -- Fallback to direct ID match
          )

        UNION ALL

        -- 2. SETTLEMENTS (Debits)
        -- DEDUPLICATION FIX: Only include 'Debit' type transactions from the ledger.
        -- This represents the money leaving the wallet.
        SELECT 
            -t.Amount AS Amount,
            t.TransactionDate AS [Date],
            'Settled' AS Status,
            t.Description AS ReferenceId,
            NULL AS ResidentName,
            a.Name AS UnitName,
            -- Map the transaction to the user requesting the history if they are an occupant
            @UserId AS UserId, 
            t.AssetId
        FROM assoc.Transactions t
        INNER JOIN assoc.Assets a ON t.AssetId = a.AssetId
        WHERE t.TenantId = @TenantId
          AND t.Type = 'Debit' -- ONLY WALLET WITHDRAWAL
          AND t.Category IN ('Credit Settlement', 'Internal Credit Transfer')
          AND (@AssociationId IS NULL OR t.AssociationId = @AssociationId)
          -- SECURITY: Resolve Assets belonging to this email OR directly to this UserId
          AND (@UserId IS NULL OR t.AssetId IN (
              SELECT DISTINCT oc.AssetId 
              FROM assoc.Occupancy oc
              INNER JOIN assoc.Persons per ON oc.PersonId = per.PersonId
              WHERE (per.Email = @UserEmail OR per.Email = (SELECT Email FROM assoc.Users WHERE UserId = @UserId AND TenantId = @TenantId))
                AND oc.TenantId = @TenantId
              
              UNION
              
              SELECT DISTINCT pay.AssetId 
              FROM assoc.Payments pay
              LEFT JOIN corp.Users gcu ON pay.UserId = gcu.UserId
              LEFT JOIN assoc.Users lau ON pay.UserId = lau.UserId AND pay.TenantId = @TenantId
              WHERE (
                     (@UserEmail IS NOT NULL AND (gcu.Email = @UserEmail OR lau.Email = @UserEmail))
                     OR pay.UserId = @UserId
                    ) 
                AND pay.TenantId = @TenantId
          ))
    ),
    FilteredAdvances AS (
        SELECT 
            Amount,
            [Date],
            Status,
            ReferenceId,
            ISNULL(ResidentName, 'System') AS ResidentName,
            ISNULL(UnitName, 'General') AS UnitName,
            COUNT(*) OVER() as TotalCount
        FROM RawAdvances
        WHERE (@AssetId IS NULL OR AssetId = @AssetId)
          AND (
               @Status IS NULL 
               OR Status = @Status 
               OR (@Status = 'Paid' AND Status = 'Settled') 
               OR (@Status = 'Settled' AND Status = 'Settled')
          )
          AND (@StartDate IS NULL OR [Date] >= @StartDate)
          AND (@EndDate IS NULL OR [Date] <= @EndDate)
          AND (@SearchTerm IS NULL 
               OR ResidentName LIKE '%' + @SearchTerm + '%' 
               OR UnitName LIKE '%' + @SearchTerm + '%'
               OR ReferenceId LIKE '%' + @SearchTerm + '%'
          )
    )
    SELECT 
        * 
    FROM FilteredAdvances
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'ResidentName' THEN ResidentName
                WHEN @SortColumn = 'UnitName' THEN UnitName
                WHEN @SortColumn = 'Status' THEN Status
                WHEN @SortColumn = 'ReferenceId' THEN ReferenceId
            END
        END DESC,
        CASE WHEN @SortDirection = 'ASC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END ASC,
        CASE WHEN @SortDirection = 'DESC' THEN
            CASE 
                WHEN @SortColumn = 'Amount' THEN Amount
                WHEN @SortColumn = 'Date' THEN CAST([Date] AS SQL_VARIANT)
            END
        END DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO