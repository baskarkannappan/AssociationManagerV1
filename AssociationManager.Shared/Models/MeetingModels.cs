using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class Meeting
{
    public int MeetingId { get; set; }
    public int AssociationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public DateTime MeetingDate { get; set; }
    public string? Description { get; set; }
    public int CreatedBy { get; set; }
    public DateTime CreatedDate { get; set; }
    public List<MeetingMinutes> Minutes { get; set; } = new();
}

public class MeetingMinutes
{
    public int MinutesId { get; set; }
    public int MeetingId { get; set; }
    public string? Notes { get; set; }
    public string? DocumentUrl { get; set; }
    public DateTime CreatedDate { get; set; }
}
