-- 3. Update Associations List Stored Procedure to include Billing Account Name
CREATE   PROCEDURE corp.sp_Associations_List
AS
BEGIN
    SELECT 
        a.*,
        pa.AccountName as BillingAccountName
    FROM corp.Associations a
    LEFT JOIN corp.PlatformAccounts pa ON a.PlatformAccountId = pa.Id;
END;