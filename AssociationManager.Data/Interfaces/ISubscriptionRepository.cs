using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface ISubscriptionRepository
{
    Task<IEnumerable<SubscriptionPlan>> GetAllPlansAsync();
    Task<AssociationSubscription?> GetByAssociationIdAsync(int associationId);
    Task<bool> UpsertSubscriptionAsync(AssociationSubscription subscription);
}
