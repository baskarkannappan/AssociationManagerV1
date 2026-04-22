-- 2. Analyze Asset Financials (Invoices & Balance)
CREATE   PROCEDURE assoc.sp_Analyze_AssetFinancials
    @AssetId INT
AS
BEGIN
    -- Summary
    SELECT 
        a.Name AS AssetName,
        (SELECT SUM(CASE WHEN Type = 'Debit' THEN Amount ELSE -Amount END) FROM assoc.Transactions WHERE AssetId = @AssetId) AS CurrentBalance
    FROM assoc.Assets a WHERE a.AssetId = @AssetId;

    -- Recent Invoices
    SELECT TOP 20
        InvoiceId, Title, Amount, Status, CreatedDate, DueDate
    FROM assoc.Invoices 
    WHERE AssetId = @AssetId
    ORDER BY CreatedDate DESC;

    -- Recent Transactions
    SELECT TOP 20
        TransactionId, Type, Amount, Category, Description, TransactionDate
    FROM assoc.Transactions
    WHERE AssetId = @AssetId
    ORDER BY TransactionDate DESC;
END