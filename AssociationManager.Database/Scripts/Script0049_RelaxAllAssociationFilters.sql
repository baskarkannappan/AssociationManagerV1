-- Script0049_RelaxAllAssociationFilters.sql
-- Relax TenantId filtering in association-level stored procedures to fix empty dashboard data.

PRINT 'Relaxing TenantId filters in Finance procedures...'
GO

-- INVOICES
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT i.*, a.Name as AssetName 
    FROM assoc.Invoices i 
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId 
    WHERE i.InvoiceId = @Id AND i.AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT i.*, a.Name as AssetName 
    FROM assoc.Invoices i 
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId 
    WHERE i.AssociationId = @AssociationId 
    ORDER BY i.DueDate DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT i.*, a.Name as AssetName 
    FROM assoc.Invoices i 
    LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId 
    WHERE i.AssetId = @AssetId AND i.AssociationId = @AssociationId 
    ORDER BY i.DueDate DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Invoices_UpdateStatus @Id INT, @Status NVARCHAR(50), @TenantId INT, @AssociationId INT AS 
BEGIN 
    UPDATE assoc.Invoices SET Status = @Status 
    WHERE InvoiceId = @Id AND AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Invoices_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Invoices 
    WHERE InvoiceId = @Id AND AssociationId = @AssociationId; 
END
GO

-- PAYMENTS
CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Payments 
    WHERE PaymentId = @Id AND AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Payments 
    WHERE AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Payments_UpdateStatus @Id INT, @Status NVARCHAR(50), @GatewayReference NVARCHAR(255) = NULL, @TenantId INT, @AssociationId INT AS 
BEGIN 
    UPDATE assoc.Payments SET Status = @Status, GatewayReference = @GatewayReference 
    WHERE PaymentId = @Id AND AssociationId = @AssociationId; 
END
GO

-- TRANSACTIONS
CREATE OR ALTER PROCEDURE assoc.sp_Transactions_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Transactions 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId 
    ORDER BY TransactionDate DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Transactions_GetByTenantId @TenantId INT, @AssociationId INT, @StartDate DATETIME, @EndDate DATETIME AS 
BEGIN 
    SELECT * FROM assoc.Transactions 
    WHERE AssociationId = @AssociationId AND TransactionDate BETWEEN @StartDate AND @EndDate 
    ORDER BY TransactionDate DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Transactions_GetBalanceByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT ISNULL(SUM(CASE WHEN Type = 'Credit' THEN Amount ELSE -Amount END), 0) 
    FROM assoc.Transactions 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END
GO

PRINT 'Relaxing TenantId filters in Operations procedures...'
GO

-- WORK ORDERS
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT w.*, a.Name as AssetName 
    FROM assoc.WorkOrders w 
    LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId 
    WHERE w.WorkOrderId = @Id AND w.AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT w.*, a.Name as AssetName 
    FROM assoc.WorkOrders w 
    LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId 
    WHERE w.AssociationId = @AssociationId 
    ORDER BY w.CreatedDate DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT w.*, a.Name as AssetName 
    FROM assoc.WorkOrders w 
    LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId 
    WHERE w.AssetId = @AssetId AND w.AssociationId = @AssociationId 
    ORDER BY w.CreatedDate DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_UpdateStatus @Id INT, @Status NVARCHAR(50), @TenantId INT, @AssociationId INT AS 
BEGIN 
    UPDATE assoc.WorkOrders SET Status = @Status 
    WHERE WorkOrderId = @Id AND AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.WorkOrders 
    WHERE WorkOrderId = @Id AND AssociationId = @AssociationId; 
END
GO

PRINT 'Relaxing TenantId filters in Communications procedures...'
GO

-- BROADCASTS
CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.BroadcastId = @Id AND b.AssociationId = @AssociationId;
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.AssociationId = @AssociationId
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN
    SELECT b.*, u.Name as AuthorName, a.Name as AssetName
    FROM assoc.Broadcasts b 
    LEFT JOIN corp.Users u ON b.CreatedBy = u.UserId
    LEFT JOIN assoc.Assets a ON b.AssetId = a.AssetId
    WHERE b.AssociationId = @AssociationId AND (b.AssetId = @AssetId OR b.AssetId IS NULL)
    ORDER BY b.IsPinned DESC, b.CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Broadcasts_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Broadcasts 
    WHERE BroadcastId = @Id AND AssociationId = @AssociationId; 
END
GO

PRINT 'Relaxing TenantId filters in Audit and Resident procedures...'
GO

-- AUDIT
CREATE OR ALTER PROCEDURE corp.sp_AuditLogs_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM corp.AuditLogs 
    WHERE AssociationId = @AssociationId 
    ORDER BY Timestamp DESC; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_AuditLogs_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM corp.AuditLogs 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId 
    ORDER BY Timestamp DESC; 
END
GO

-- VEHICLES
CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Vehicles 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Vehicles_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Vehicles 
    WHERE VehicleId = @Id AND AssociationId = @AssociationId; 
END
GO

-- PETS
CREATE OR ALTER PROCEDURE assoc.sp_Pets_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    SELECT * FROM assoc.Pets 
    WHERE AssetId = @AssetId AND AssociationId = @AssociationId; 
END
GO

CREATE OR ALTER PROCEDURE assoc.sp_Pets_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN 
    DELETE FROM assoc.Pets 
    WHERE PetId = @Id AND AssociationId = @AssociationId; 
END
GO

PRINT 'Script 0049 Complete.'
GO
