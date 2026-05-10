CREATE NONCLUSTERED INDEX [IX_Invoices_Performance_Covering]
    ON [assoc].[Invoices]([TenantId] ASC, [AssociationId] ASC, [Status] ASC)
    INCLUDE ([Amount], [DueDate], [CreatedDate]);
