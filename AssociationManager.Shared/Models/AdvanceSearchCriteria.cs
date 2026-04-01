using System;

namespace AssociationManager.Shared.Models;

public class AdvanceSearchCriteria
{
    public int? TenantId { get; set; }
    public int? AssociationId { get; set; }
    public int? UserId { get; set; }
    public int? AssetId { get; set; }
    
    public string? SearchTerm { get; set; }
    public string? Status { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string SortColumn { get; set; } = "Date";
    public string SortDirection { get; set; } = "DESC";
}
