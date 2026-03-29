
-- Update Stored Procedure
CREATE   PROCEDURE corp.sp_PlatformInvoices_Insert
    @AssociationId INT,
    @PlanId INT,
    @Amount DECIMAL(18,2),
    @BillingDate DATETIME,
    @DueDate DATETIME
AS
BEGIN
    INSERT INTO corp.PlatformInvoices (AssociationId, PlanId, Amount, BillingDate, DueDate)
    VALUES (@AssociationId, @PlanId, @Amount, @BillingDate, @DueDate);
    SELECT SCOPE_IDENTITY();
END;