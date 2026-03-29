-- Fix Transaction Creation Procedure to match Repository
CREATE OR ALTER PROCEDURE assoc.sp_Transactions_Create
    @TenantId INT,
    @AssociationId INT,
    @AssetId INT,
    @InvoiceId INT = NULL,
    @PaymentId INT = NULL,
    @Type NVARCHAR(50),
    @Amount DECIMAL(18, 2),
    @Category NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @TransactionDate DATETIME
AS
BEGIN
    INSERT INTO assoc.Transactions (
        TenantId,
        AssociationId,
        AssetId,
        InvoiceId,
        PaymentId,
        Type,
        Amount,
        Category,
        Description,
        TransactionDate
    )
    VALUES (
        @TenantId,
        @AssociationId,
        @AssetId,
        @InvoiceId,
        @PaymentId,
        @Type,
        @Amount,
        @Category,
        @Description,
        @TransactionDate
    );
    
    SELECT SCOPE_IDENTITY();
END
GO
