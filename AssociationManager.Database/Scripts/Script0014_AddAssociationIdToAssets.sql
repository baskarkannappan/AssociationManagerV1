USE AssociationManagerV1;
GO

-- 1. Ensure all tenants have at least one association (needed for isolation)
-- If a tenant has no associations, create a default one
INSERT INTO Associations (TenantId, Name, Description, CreatedDate)
SELECT DISTINCT t.TenantId, 'Main Association', 'Auto-generated default association', GETDATE()
FROM Tenants t
LEFT JOIN Associations a ON t.TenantId = a.TenantId
WHERE a.AssociationId IS NULL;
GO

-- 2. Define the list of tables to isolate (including those I missed before)
DECLARE @TableList TABLE (TableName NVARCHAR(100));
INSERT INTO @TableList VALUES 
('Assets'), ('Persons'), ('Occupancy'), ('Vehicles'), 
('Pets'), ('WorkOrders'), ('Broadcasts'), ('Invoices'), 
('Payments'), ('AuditLogs'), ('Transactions');

DECLARE @TableName NVARCHAR(100);
DECLARE table_cursor CURSOR FOR SELECT TableName FROM @TableList;
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @Sql NVARCHAR(MAX);
    
    -- Check if Table exists before proceeding
    IF EXISTS (SELECT * FROM sys.tables WHERE name = @TableName)
    BEGIN
        -- Add AssociationId as NULL first
        IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(@TableName) AND name = 'AssociationId')
        BEGIN
            SET @Sql = 'ALTER TABLE ' + @TableName + ' ADD AssociationId INT NULL;';
            EXEC sp_executesql @Sql;

            -- Populate AssociationId from the first association of the tenant
            SET @Sql = 'UPDATE t SET t.AssociationId = (SELECT TOP 1 AssociationId FROM Associations WHERE TenantId = t.TenantId) FROM ' + @TableName + ' t;';
            EXEC sp_executesql @Sql;

            -- Safety check: If for some reason it''s still NULL (shouldn''t be now), we might fail on NOT NULL
            -- But we ensures above that all tenants have an association.
            
            SET @Sql = 'ALTER TABLE ' + @TableName + ' ALTER COLUMN AssociationId INT NOT NULL;';
            EXEC sp_executesql @Sql;

            -- Add Foreign Key if not exists
            IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_' + @TableName + '_Associations')
            BEGIN
                SET @Sql = 'ALTER TABLE ' + @TableName + ' ADD CONSTRAINT FK_' + @TableName + '_Associations FOREIGN KEY (AssociationId) REFERENCES Associations(AssociationId);';
                EXEC sp_executesql @Sql;
            END

            -- Add Index
            IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_' + @TableName + '_AssociationId')
            BEGIN
                SET @Sql = 'CREATE INDEX IX_' + @TableName + '_AssociationId ON ' + @TableName + '(AssociationId);';
                EXEC sp_executesql @Sql;
            END
        END
    END
    
    FETCH NEXT FROM table_cursor INTO @TableName;
END
CLOSE table_cursor;
DEALLOCATE table_cursor;
GO
