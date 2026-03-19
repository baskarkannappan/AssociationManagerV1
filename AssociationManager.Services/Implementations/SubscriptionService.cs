using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class SubscriptionService : ISubscriptionService
{
    private readonly ISubscriptionRepository _subscriptionRepository;
    private readonly IAssetRepository _assetRepository;

    public SubscriptionService(ISubscriptionRepository subscriptionRepository, IAssetRepository assetRepository)
    {
        _subscriptionRepository = subscriptionRepository;
        _assetRepository = assetRepository;
    }

    public async Task<IEnumerable<SubscriptionPlan>> GetPlansAsync()
    {
        return await _subscriptionRepository.GetAllPlansAsync();
    }

    public async Task<AssociationSubscription?> GetSubscriptionAsync(int associationId)
    {
        return await _subscriptionRepository.GetByAssociationIdAsync(associationId);
    }

    public async Task<bool> SubscribeAsync(int associationId, int planId)
    {
        var subscription = new AssociationSubscription
        {
            AssociationId = associationId,
            PlanId = planId,
            Status = "Active",
            NextBillingDate = DateTime.UtcNow.AddMonths(1)
        };
        return await _subscriptionRepository.UpsertSubscriptionAsync(subscription);
    }

    public async Task<decimal> CalculateNextBillAsync(int associationId)
    {
        var subscription = await _subscriptionRepository.GetByAssociationIdAsync(associationId);
        if (subscription == null) return 0;

        int assetCount = await _assetRepository.CountAsync(subscription.TenantId, associationId);
        
        return subscription.BasePrice + (assetCount * subscription.PricePerAsset);
    }
}
