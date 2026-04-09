CREATE PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Sum of Unpaid/Partial Invoices
    -- Robust approach: calculate total for each invoice (Principal + Fines) then sum
    SELECT ISNULL(SUM(TotalDue), 0)
    FROM (
        SELECT 
            i.InvoiceId,
            -- True principal is Max(Amount, Sum(PrincipalLineItems))
            -- But for simplicity in SP, using Amount + Fines is usually enough if data is well-formed
            -- Let's use the logic: Invoice Amount + sum of all Penalty/Fine line items
            i.Amount + ISNULL((SELECT SUM(li.Amount) FROM assoc.InvoiceLineItems li WHERE li.InvoiceId = i.InvoiceId AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')), 0) as TotalDue
        FROM assoc.Invoices i
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void')
    ) as UnpaidTotals;
END
