CREATE PROCEDURE assoc.sp_Dashboard_GetNetOutstanding
    @TenantId INT,
    @AssociationId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ISNULL(SUM(TotalDue), 0)
    FROM (
        SELECT 
            i.InvoiceId,
            i.Amount + ISNULL((SELECT SUM(li.Amount) FROM assoc.InvoiceLineItems li WHERE li.InvoiceId = i.InvoiceId AND (li.ChargeName LIKE '%Penalty%' OR li.ChargeName LIKE '%Fine%')), 0) as TotalDue
        FROM assoc.Invoices i
        WHERE i.TenantId = @TenantId 
        AND i.AssociationId = @AssociationId 
        AND i.Status NOT IN ('Paid', 'Cancelled', 'Void')
    ) as UnpaidTotals;
END