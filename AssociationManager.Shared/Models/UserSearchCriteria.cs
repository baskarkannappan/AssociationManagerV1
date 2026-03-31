using System;

namespace AssociationManager.Shared.Models;

public class UserSearchCriteria
{
    public int? AssociationId { get; set; }
    public string? SearchTerm { get; set; }
    public string? Role { get; set; }
    
    // Paging/Sorting
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string? SortColumn { get; set; } = "Name";
    public string? SortDirection { get; set; } = "ASC";
}
