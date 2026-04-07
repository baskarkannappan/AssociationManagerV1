using System.Threading.Tasks;

namespace AssociationManager.Shared.Interfaces;

public class SecurityContext
{
    public string UserRole { get; set; } = string.Empty;
    public int UserLevel { get; set; }
    public bool IsOwner { get; set; }
    public bool IsPrimaryResident { get; set; }
    public string Action { get; set; } = string.Empty;
    public string Resource { get; set; } = string.Empty;
    public int AssociationId { get; set; }
    public int? AssetId { get; set; }
    public string AssociationStatus { get; set; } = "Active";
}

public class FineCalculationContext
{
    public decimal OriginalAmount { get; set; }
    public int DaysLate { get; set; }
    public int MonthsLate { get; set; }
    public decimal Rate { get; set; }
    public decimal FlatAmount { get; set; }
    public bool IsCompounding { get; set; }
}

public interface IRuleEngineService
{
    Task<bool> EvaluateRuleAsync(string workflowName, SecurityContext context);
    Task<decimal> CalculateValueAsync(string workflowName, FineCalculationContext context);
}
