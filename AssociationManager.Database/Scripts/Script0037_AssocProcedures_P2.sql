-- INVOICES
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT i.*, a.Name as AssetName FROM assoc.Invoices i LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId WHERE i.InvoiceId = @Id AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN SELECT i.*, a.Name as AssetName FROM assoc.Invoices i LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId ORDER BY i.DueDate DESC; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT i.*, a.Name as AssetName FROM assoc.Invoices i LEFT JOIN assoc.Assets a ON i.AssetId = a.AssetId WHERE i.AssetId = @AssetId AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId ORDER BY i.DueDate DESC; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_Create @TenantId INT, @AssociationId INT, @AssetId INT = NULL, @Title NVARCHAR(200), @Description NVARCHAR(MAX) = NULL, @Amount DECIMAL(18, 2), @DueDate DATETIME, @Status NVARCHAR(50), @CreatedDate DATETIME AS 
BEGIN INSERT INTO assoc.Invoices (TenantId, AssociationId, AssetId, Title, Description, Amount, DueDate, Status, CreatedDate) OUTPUT INSERTED.InvoiceId VALUES (@TenantId, @AssociationId, @AssetId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_UpdateStatus @Id INT, @Status NVARCHAR(50), @TenantId INT, @AssociationId INT AS 
BEGIN UPDATE assoc.Invoices SET Status = @Status WHERE InvoiceId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Invoices_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.Invoices WHERE InvoiceId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO

-- PAYMENTS
CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Payments WHERE PaymentId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Payments_GetByTenantId @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Payments_Create @TenantId INT, @AssociationId INT, @UserId INT = NULL, @Amount DECIMAL(18, 2), @Currency NVARCHAR(10), @Status NVARCHAR(50), @CreatedDate DATETIME, @GatewayReference NVARCHAR(255) = NULL AS 
BEGIN INSERT INTO assoc.Payments (TenantId, AssociationId, UserId, Amount, Currency, Status, CreatedDate, GatewayReference) OUTPUT INSERTED.PaymentId VALUES (@TenantId, @AssociationId, @UserId, @Amount, @Currency, @Status, @CreatedDate, @GatewayReference); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Payments_UpdateStatus @Id INT, @Status NVARCHAR(50), @GatewayReference NVARCHAR(255) = NULL, @TenantId INT, @AssociationId INT AS 
BEGIN UPDATE assoc.Payments SET Status = @Status, GatewayReference = @GatewayReference WHERE PaymentId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO

-- TRANSACTIONS
CREATE OR ALTER PROCEDURE assoc.sp_Transactions_Create @TenantId INT, @AssociationId INT, @AssetId INT, @Amount DECIMAL(18, 2), @Type NVARCHAR(50), @TransactionDate DATETIME, @Description NVARCHAR(MAX) = NULL AS 
BEGIN INSERT INTO assoc.Transactions (TenantId, AssociationId, AssetId, Amount, Type, TransactionDate, Description) OUTPUT INSERTED.TransactionId VALUES (@TenantId, @AssociationId, @AssetId, @Amount, @Type, @TransactionDate, @Description); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Transactions_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT * FROM assoc.Transactions WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId ORDER BY TransactionDate DESC; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Transactions_GetByTenantId @TenantId INT, @AssociationId INT, @StartDate DATETIME, @EndDate DATETIME AS 
BEGIN SELECT * FROM assoc.Transactions WHERE TenantId = @TenantId AND AssociationId = @AssociationId AND TransactionDate BETWEEN @StartDate AND @EndDate ORDER BY TransactionDate DESC; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_Transactions_GetBalanceByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT ISNULL(SUM(CASE WHEN Type = 'Credit' THEN Amount ELSE -Amount END), 0) FROM assoc.Transactions WHERE AssetId = @AssetId AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO

-- WORK ORDERS
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_GetById @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT w.*, a.Name as AssetName FROM assoc.WorkOrders w LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId WHERE w.WorkOrderId = @Id AND w.TenantId = @TenantId AND w.AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_GetAll @TenantId INT, @AssociationId INT AS 
BEGIN SELECT w.*, a.Name as AssetName FROM assoc.WorkOrders w LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId WHERE w.TenantId = @TenantId AND w.AssociationId = @AssociationId ORDER BY w.CreatedDate DESC; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_GetByAssetId @AssetId INT, @TenantId INT, @AssociationId INT AS 
BEGIN SELECT w.*, a.Name as AssetName FROM assoc.WorkOrders w LEFT JOIN assoc.Assets a ON w.AssetId = a.AssetId WHERE w.AssetId = @AssetId AND w.TenantId = @TenantId AND w.AssociationId = @AssociationId ORDER BY w.CreatedDate DESC; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_Create @TenantId INT, @AssociationId INT, @AssetId INT = NULL, @Title NVARCHAR(200), @Description NVARCHAR(MAX) = NULL, @Priority NVARCHAR(50), @Status NVARCHAR(50), @CreatedDate DATETIME, @CreatedBy INT AS 
BEGIN INSERT INTO assoc.WorkOrders (TenantId, AssociationId, AssetId, Title, Description, Priority, Status, CreatedDate, CreatedBy) OUTPUT INSERTED.WorkOrderId VALUES (@TenantId, @AssociationId, @AssetId, @Title, @Description, @Priority, @Status, @CreatedDate, @CreatedBy); END
GO
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_Update @WorkOrderId INT, @Title NVARCHAR(200), @Description NVARCHAR(MAX) = NULL, @Priority NVARCHAR(50), @Status NVARCHAR(50) AS 
BEGIN UPDATE assoc.WorkOrders SET Title = @Title, Description = @Description, Priority = @Priority, Status = @Status WHERE WorkOrderId = @WorkOrderId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_UpdateStatus @Id INT, @Status NVARCHAR(50), @TenantId INT, @AssociationId INT AS 
BEGIN UPDATE assoc.WorkOrders SET Status = @Status WHERE WorkOrderId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
CREATE OR ALTER PROCEDURE assoc.sp_WorkOrders_Delete @Id INT, @TenantId INT, @AssociationId INT AS 
BEGIN DELETE FROM assoc.WorkOrders WHERE WorkOrderId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId; END
GO
