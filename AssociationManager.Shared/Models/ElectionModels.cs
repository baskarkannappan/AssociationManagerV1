using System;
using System.Collections.Generic;

namespace AssociationManager.Shared.Models;

public class Election
{
    public int ElectionId { get; set; }
    public int AssociationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
    public List<Candidate> Candidates { get; set; } = new();
}

public class Candidate
{
    public int CandidateId { get; set; }
    public int ElectionId { get; set; }
    public int MemberId { get; set; }
    public string? MemberName { get; set; } // Flattened
}

public class Vote
{
    public int VoteId { get; set; }
    public int ElectionId { get; set; }
    public int MemberId { get; set; }
    public int CandidateId { get; set; }
    public DateTime VoteDate { get; set; }
}

public class ElectionResult
{
    public string CandidateName { get; set; } = string.Empty;
    public int VoteCount { get; set; }
}
