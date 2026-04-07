CREATE   PROCEDURE corp.sp_PlatformAdvancePayments_Insert
    @AssociationId INT,
    @Amount DECIMAL(18,2),
    @Status NVARCHAR(50),
    @TransactionRef NVARCHAR(255) = NULL,
    @Description NVARCHAR(500) = NULL,
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO corp.PlatformAdvancePayments (AssociationId, Amount, Status, TransactionRef, Description, Notes)
    VALUES (@AssociationId, @Amount, @Status, @TransactionRef, @Description, @Notes);
    SELECT SCOPE_IDENTITY();
END;