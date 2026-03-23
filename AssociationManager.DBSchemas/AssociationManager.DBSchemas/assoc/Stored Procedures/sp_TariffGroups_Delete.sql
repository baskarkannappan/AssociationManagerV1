CREATE   PROCEDURE assoc.sp_TariffGroups_Delete @GroupId INT AS 
BEGIN DELETE FROM assoc.TariffGroups WHERE TariffGroupId = @GroupId; END