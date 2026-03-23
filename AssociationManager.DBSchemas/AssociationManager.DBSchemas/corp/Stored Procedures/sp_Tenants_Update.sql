CREATE   PROCEDURE corp.sp_Tenants_Update @TenantId INT, @Name NVARCHAR(255), @IsActive BIT AS 
BEGIN UPDATE corp.Tenants SET Name = @Name, IsActive = @IsActive WHERE TenantId = @TenantId; END