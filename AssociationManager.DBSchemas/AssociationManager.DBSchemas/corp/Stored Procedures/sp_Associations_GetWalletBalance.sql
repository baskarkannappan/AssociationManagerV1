-- 3. Stored Procedures for Wallet Management

CREATE   PROCEDURE corp.sp_Associations_GetWalletBalance
    @AssociationId INT
AS
BEGIN
    SELECT ISNULL(PlatformWalletBalance, 0) FROM corp.Associations WHERE AssociationId = @AssociationId;
END;