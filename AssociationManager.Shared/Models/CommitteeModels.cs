using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class CommitteeRole
{
    public int RoleId { get; set; }
    public string RoleName { get; set; } = string.Empty;
}

public class CommitteeMember
{
    public int CommitteeMemberId { get; set; }
    public int AssociationId { get; set; }
    public int? MemberId { get; set; }
    public string? MemberName { get; set; } // Flattened for UI
    public int RoleId { get; set; }
    public string? RoleName { get; set; }   // Flattened for UI
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive { get; set; }
}
