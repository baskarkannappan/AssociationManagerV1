using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class PagedResult<T>
{
    public IEnumerable<T> Items { get; set; } = new List<T>();
    public int TotalCount { get; set; }
    public int FilteredCount { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    
    // Summary Stats for Billing Dashboard
    public decimal TotalUnpaid { get; set; }
    public decimal Collected30Days { get; set; }
}

public class InvoiceSearchCriteria
{
    public int? AssociationId { get; set; }
    public int? AssetId { get; set; }
    public List<int>? AssetIds { get; set; }
    public string? SearchTerm { get; set; }
    public string? Status { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    
    // Paging/Sorting
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public string? SortColumn { get; set; } = "CreatedDate";
    public string? SortDirection { get; set; } = "DESC";
    public bool IncludeDrafts { get; set; }
}
