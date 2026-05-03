using System;

namespace AssociationManager.Shared.Models;

public class StaticContent
{
    public string ContentKey { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string HtmlContent { get; set; } = string.Empty;
    public DateTime LastUpdated { get; set; }
    public int? UpdatedBy { get; set; }
}
