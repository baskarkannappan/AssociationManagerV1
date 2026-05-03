using System;

namespace AssociationManager.Shared.Models;

public class SupportQuery
{
    public int QueryId { get; set; }
    public int? UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string MessageBody { get; set; } = string.Empty;
    public string Status { get; set; } = "New";
    public DateTime CreatedDate { get; set; }
}
