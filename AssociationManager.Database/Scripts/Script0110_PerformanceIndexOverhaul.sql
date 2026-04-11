-- Script0110_PerformanceIndexOverhaul.sql
-- Optimizes high-volume tables with missing indices for faster retrieval and join performance.

-- 1. Indexing AuditLogs for better traceability and time-range filtering
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('corp.AuditLogs') AND name = 'IX_AuditLogs_Timestamp')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_AuditLogs_Timestamp] ON [corp].[AuditLogs]([Timestamp] DESC);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('corp.AuditLogs') AND name = 'IX_AuditLogs_CorrelationId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_AuditLogs_CorrelationId] ON [corp].[AuditLogs]([CorrelationId] ASC);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('corp.AuditLogs') AND name = 'IX_AuditLogs_TenantId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_AuditLogs_TenantId] ON [corp].[AuditLogs]([TenantId] ASC);
END

-- 2. Indexing PlatformInvoices for status check and plan joins
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('corp.PlatformInvoices') AND name = 'IX_PlatformInvoices_Status')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PlatformInvoices_Status] ON [corp].[PlatformInvoices]([Status] ASC);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('corp.PlatformInvoices') AND name = 'IX_PlatformInvoices_PlanId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PlatformInvoices_PlanId] ON [corp].[PlatformInvoices]([PlanId] ASC);
END

-- 3. Indexing association Invoices for high-frequency billing queries
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('assoc.Invoices') AND name = 'IX_Invoices_Status')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Invoices_Status] ON [assoc].[Invoices]([Status] ASC);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('assoc.Invoices') AND name = 'IX_Invoices_AssetId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Invoices_AssetId] ON [assoc].[Invoices]([AssetId] ASC);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('assoc.Invoices') AND name = 'IX_Invoices_BillingBatchId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Invoices_BillingBatchId] ON [assoc].[Invoices]([BillingBatchId] ASC);
END
GO
