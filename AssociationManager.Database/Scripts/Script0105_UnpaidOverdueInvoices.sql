-- Script0105_UnpaidOverdueInvoices.sql
-- Deploys the stored procedure for retrieving overdue invoices for automated fine posting

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[assoc].[sp_Invoices_GetUnpaidOverdue]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [assoc].[sp_Invoices_GetUnpaidOverdue];
GO

CREATE PROCEDURE [assoc].[sp_Invoices_GetUnpaidOverdue]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT i.*
    FROM [assoc].[Invoices] i
    WHERE i.[Status] IN ('Unpaid', 'PartiallyPaid', 'Overdue')
      AND i.[DueDate] < GETUTCDATE()
      -- Selection Logic: Ensure they actually have a remaining balance
      AND EXISTS (
          SELECT 1 FROM [assoc].[InvoiceLineItems] li WHERE li.InvoiceId = i.InvoiceId
          GROUP BY li.InvoiceId
          HAVING SUM(li.Amount) > (SELECT ISNULL(SUM(p.Amount), 0) FROM [assoc].[Payments] p WHERE p.InvoiceId = i.InvoiceId AND p.Status = 'Paid')
      );
END
GO
