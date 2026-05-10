namespace AssociationManager.Shared.Models;

public class EmailMessage
{
    public string ToEmail { get; set; } = string.Empty;
    public string ToName { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string HtmlBody { get; set; } = string.Empty;
    public string? FromEmail { get; set; }
    public string? FromName { get; set; }
}
