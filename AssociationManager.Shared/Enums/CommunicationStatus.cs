using System;

namespace AssociationManager.Shared.Enums;

public enum CommunicationStatus
{
    Posted = 1,
    InProgress = 2,
    Sent = 3,
    Success = 4,
    Failure = 5,
    Complete = 6,
    Resend = 7,
    Archive = 8
}
