-- Upsert Bank Details
CREATE   PROCEDURE assoc.sp_AssociationBankDetails_Upsert
    @AssociationId INT,
    @TenantId INT,
    @PrimaryAccountName NVARCHAR(255) = NULL,
    @PrimaryAccountNumber NVARCHAR(50) = NULL,
    @PrimaryIFSCCode NVARCHAR(20) = NULL,
    @PrimaryBankName NVARCHAR(255) = NULL,
    @PrimaryBranchName NVARCHAR(255) = NULL,
    @PrimaryQRCode VARBINARY(MAX) = NULL,
    @PrimaryQRCodeContentType NVARCHAR(100) = NULL,
    @SecondaryAccountName NVARCHAR(255) = NULL,
    @SecondaryAccountNumber NVARCHAR(50) = NULL,
    @SecondaryIFSCCode NVARCHAR(20) = NULL,
    @SecondaryBankName NVARCHAR(255) = NULL,
    @SecondaryBranchName NVARCHAR(255) = NULL,
    @SecondaryQRCode VARBINARY(MAX) = NULL,
    @SecondaryQRCodeContentType NVARCHAR(100) = NULL,
    @UserId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM assoc.AssociationBankDetails WHERE AssociationId = @AssociationId)
    BEGIN
        UPDATE assoc.AssociationBankDetails
        SET 
            PrimaryAccountName = @PrimaryAccountName,
            PrimaryAccountNumber = @PrimaryAccountNumber,
            PrimaryIFSCCode = @PrimaryIFSCCode,
            PrimaryBankName = @PrimaryBankName,
            PrimaryBranchName = @PrimaryBranchName,
            PrimaryQRCode = ISNULL(@PrimaryQRCode, PrimaryQRCode),
            PrimaryQRCodeContentType = ISNULL(@PrimaryQRCodeContentType, PrimaryQRCodeContentType),
            SecondaryAccountName = @SecondaryAccountName,
            SecondaryAccountNumber = @SecondaryAccountNumber,
            SecondaryIFSCCode = @SecondaryIFSCCode,
            SecondaryBankName = @SecondaryBankName,
            SecondaryBranchName = @SecondaryBranchName,
            SecondaryQRCode = ISNULL(@SecondaryQRCode, SecondaryQRCode),
            SecondaryQRCodeContentType = ISNULL(@SecondaryQRCodeContentType, SecondaryQRCodeContentType),
            LastUpdatedBy = @UserId,
            LastUpdatedDate = GETUTCDATE()
        WHERE AssociationId = @AssociationId;
    END
    ELSE
    BEGIN
        INSERT INTO assoc.AssociationBankDetails (
            AssociationId, TenantId, PrimaryAccountName, PrimaryAccountNumber, PrimaryIFSCCode, PrimaryBankName, PrimaryBranchName, PrimaryQRCode, PrimaryQRCodeContentType,
            SecondaryAccountName, SecondaryAccountNumber, SecondaryIFSCCode, SecondaryBankName, SecondaryBranchName, SecondaryQRCode, SecondaryQRCodeContentType,
            CreatedBy, CreatedDate
        )
        VALUES (
            @AssociationId, @TenantId, @PrimaryAccountName, @PrimaryAccountNumber, @PrimaryIFSCCode, @PrimaryBankName, @PrimaryBranchName, @PrimaryQRCode, @PrimaryQRCodeContentType,
            @SecondaryAccountName, @SecondaryAccountNumber, @SecondaryIFSCCode, @SecondaryBankName, @SecondaryBranchName, @SecondaryQRCode, @SecondaryQRCodeContentType,
            @UserId, GETUTCDATE()
        );
    END
END;