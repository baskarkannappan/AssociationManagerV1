using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Interfaces;

public interface ISubscriptionService
{
    Task<IEnumerable<SubscriptionPlan>> GetPlansAsync();
    Task<AssociationSubscription?> GetSubscriptionAsync(int associationId);
    Task<bool> SubscribeAsync(int associationId, int planId);
    Task<decimal> CalculateNextBillAsync(int associationId);
}
