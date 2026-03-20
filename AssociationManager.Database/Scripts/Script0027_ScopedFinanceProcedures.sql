-- Update sp_Invoices_GetAll to support Corporate Level (All associations in tenant)
CREATE OR ALTER PROCEDURE sp_Invoices_GetAll
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.TenantId = @TenantId 
      AND (i.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY i.DueDate DESC;
END
GO

-- Update sp_Payments_GetByTenantId
CREATE OR ALTER PROCEDURE sp_Payments_GetByTenantId
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT * FROM Payments 
    WHERE TenantId = @TenantId 
      AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0)
    ORDER BY CreatedDate DESC;
END
GO

-- Update sp_Invoices_GetById
CREATE OR ALTER PROCEDURE sp_Invoices_GetById
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    SELECT i.*, a.Name as AssetName 
    FROM Invoices i 
    LEFT JOIN Assets a ON i.AssetId = a.AssetId
    WHERE i.InvoiceId = @Id AND i.TenantId = @TenantId
    AND (i.AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END
GO

-- Update sp_Invoices_UpdateStatus
CREATE OR ALTER PROCEDURE sp_Invoices_UpdateStatus
    @Id INT,
    @Status NVARCHAR(50),
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    UPDATE Invoices SET Status = @Status 
    WHERE InvoiceId = @Id AND TenantId = @TenantId 
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END
GO

-- Update sp_Invoices_Delete
CREATE OR ALTER PROCEDURE sp_Invoices_Delete
    @Id INT,
    @TenantId INT,
    @AssociationId INT = NULL
AS
BEGIN
    DELETE FROM Invoices 
    WHERE InvoiceId = @Id AND TenantId = @TenantId 
    AND (AssociationId = @AssociationId OR @AssociationId IS NULL OR @AssociationId = 0);
END
GO
