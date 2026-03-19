namespace AssociationManager.Shared.Models;

public record UpdateRoleRequest(string Role);
public record AddMemberRequest(string Email, string Role);
public record SubscriptionRequest(int AssociationId, int PlanId);
