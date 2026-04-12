-- Script0117_AddFinancialCalculationRule.sql
-- Documents the specific Dashboard formulas as an official Association Rule (Bye-Law)
-- This ensures transparency and a persistent reference for administrators.

DECLARE @TargetAssocId INT;

SELECT TOP 1 @TargetAssocId = AssociationId 
FROM corp.Associations 
WHERE Name = '8__ASSOC';

IF @TargetAssocId IS NOT NULL
BEGIN
    -- Check if this specific rule already exists to prevent duplicates
    IF NOT EXISTS (SELECT 1 FROM assoc.ByeLaws WHERE AssociationId = @TargetAssocId AND Title = 'Financial Standard: Dashboard Calculation Formulas')
    BEGIN
        INSERT INTO assoc.ByeLaws (
            AssociationId, 
            Title, 
            Description, 
            EffectiveDate, 
            Version, 
            IsActive
        )
        VALUES (
            @TargetAssocId,
            'Financial Standard: Dashboard Calculation Formulas',
            'OBJECTIVE: This rule defines the specific formulas used to derive financial metrics on the Association Admin Dashboard.

1. NET OUTSTANDING (₹120.00):
   Formula: [Sum of all Tariff Amounts] - [Total amount marked as Paid/Advance].
   Rationale: Provides a clear view of all uncollected revenue (172 billed - 52 paid).

2. HELD ADVANCE MONEY (₹30.00):
   Formula: [Unassigned Credits] - [Utilized Settlements].
   Rationale: Matches the "Wallet Balance" shown to individual residents for their spendable credits.

3. TOTAL REVENUE 30D (₹52.00):
   Formula: [Sum of all successful payments in last 30 days].
   Rationale: Accurately reflects all money received (22 regular + 30 advance).

These formulas ensure 100% transparency between billed revenue and the current collection state.',
            GETUTCDATE(),
            '1.2',
            1
        );
    END
END
GO
