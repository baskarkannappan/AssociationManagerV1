CREATE   PROCEDURE corp.sp_Associations_UpdateWalletBalance
    @AssociationId INT,
    @Delta DECIMAL(18,2)
AS
BEGIN
    UPDATE corp.Associations
    SET PlatformWalletBalance = ISNULL(PlatformWalletBalance, 0) + @Delta
    WHERE AssociationId = @AssociationId;
END;