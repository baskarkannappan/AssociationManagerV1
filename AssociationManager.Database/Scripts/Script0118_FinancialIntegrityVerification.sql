-- Script0118_FinancialIntegrityVerification.sql
-- Automatically runs the Financial Integrity Check after all migrations are complete.
-- Uses Output parameters where possible to avoid nesting errors.

PRINT '--- STARTING FINANCIAL INTEGRITY VERIFICATION ---';

DECLARE @AssocId INT;
DECLARE @TenantId INT;
DECLARE @AssocName NVARCHAR(255);

-- Check all active associations
DECLARE integ_cursor CURSOR FOR 
SELECT AssociationId, TenantId, Name FROM corp.Associations WHERE Status = 'Active';

OPEN integ_cursor;
FETCH NEXT FROM integ_cursor INTO @AssocId, @TenantId, @AssocName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Verifying: ' + @AssocName;
    
    DECLARE @Status NVARCHAR(50);
    
    -- We can call directly with output for the status check
    EXEC assoc.sp_Finance_ValidateIntegrity 
        @AssociationId = @AssocId, 
        @TenantId = @TenantId,
        @IntegrityStatus_OUT = @Status OUTPUT;
    
    IF @Status = 'FAILURE'
    BEGIN
        PRINT '  WARNING: Financial Drift detected in ' + @AssocName;
        -- We still do a final SELECT here to print details in the migration log
        EXEC assoc.sp_Finance_ValidateIntegrity @AssociationId = @AssocId, @TenantId = @TenantId;
    END
    ELSE
    BEGIN
        PRINT '  PASSED: Financial logic is consistent.';
    END
    
    FETCH NEXT FROM integ_cursor INTO @AssocId, @TenantId, @AssocName;
END

CLOSE integ_cursor;
DEALLOCATE integ_cursor;

PRINT '--- INTEGRITY VERIFICATION COMPLETE ---';
GO
