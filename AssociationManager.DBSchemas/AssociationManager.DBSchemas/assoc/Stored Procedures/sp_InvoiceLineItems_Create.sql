CREATE   PROCEDURE assoc.sp_InvoiceLineItems_Create 
    @InvoiceId INT, 
    @ChargeName NVARCHAR(200), 
    @Amount DECIMAL(18,2), 
    @Description NVARCHAR(MAX), 
    @TariffLayerId INT = NULL, 
    @Rate DECIMAL(18,2) = NULL 
AS 
BEGIN 
    INSERT INTO assoc.InvoiceLineItems (InvoiceId, ChargeName, Amount, Description, TariffLayerId, Rate) 
    VALUES (@InvoiceId, @ChargeName, @Amount, @Description, @TariffLayerId, @Rate); 

    SELECT SCOPE_IDENTITY();
END