-- Script0079: Registering new granular authorization rules for Asset Registry and Wallet Top-ups

IF NOT EXISTS (SELECT * FROM assoc.AuthWorkflows WHERE Name = 'CanManageGlobalAssets')
BEGIN
    INSERT INTO assoc.AuthWorkflows (Name, WorkflowJson, Description, CreatedDate, UpdatedDate)
    VALUES ('CanManageGlobalAssets', 
    '[{"WorkflowName": "CanManageGlobalAssets", "Rules": [{"RuleName": "AdminOnly", "Expression": "context.UserLevel >= 90", "SuccessEvent": "Authorized"}]}]',
    'Permission to add properties and buildings to the association registry', GETDATE(), GETDATE())
END
ELSE
BEGIN
    UPDATE assoc.AuthWorkflows 
    SET WorkflowJson = '[{"WorkflowName": "CanManageGlobalAssets", "Rules": [{"RuleName": "AdminOnly", "Expression": "context.UserLevel >= 90", "SuccessEvent": "Authorized"}]}]',
        UpdatedDate = GETDATE()
    WHERE Name = 'CanManageGlobalAssets'
END

IF NOT EXISTS (SELECT * FROM assoc.AuthWorkflows WHERE Name = 'CanAddFunds')
BEGIN
    INSERT INTO assoc.AuthWorkflows (Name, WorkflowJson, Description, CreatedDate, UpdatedDate)
    VALUES ('CanAddFunds', 
    '[{"WorkflowName": "CanAddFunds", "Rules": [{"RuleName": "ResidentOnly", "Expression": "context.UserRole.Contains(\"Resident\")", "SuccessEvent": "Authorized"}]}]',
    'Permission to top up resident wallet/advance credits', GETDATE(), GETDATE())
END
ELSE
BEGIN
    UPDATE assoc.AuthWorkflows 
    SET WorkflowJson = '[{"WorkflowName": "CanAddFunds", "Rules": [{"RuleName": "ResidentOnly", "Expression": "context.UserRole.Contains(\"Resident\")", "SuccessEvent": "Authorized"}]}]',
        UpdatedDate = GETDATE()
    WHERE Name = 'CanAddFunds'
END
GO
