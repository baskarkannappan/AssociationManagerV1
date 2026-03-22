using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Interfaces;
using Microsoft.Extensions.Caching.Distributed;
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class AssociationService : IAssociationService
{
    private readonly IAssociationRepository _associationRepository;
    private readonly ISubscriptionService _subscriptionService;
    private readonly ITenantContext _tenantContext;
    private readonly IDistributedCache _cache;

    public AssociationService(
        IAssociationRepository associationRepository,
        ISubscriptionService subscriptionService,
        ITenantContext tenantContext,
        IDistributedCache cache)
    {
        _associationRepository = associationRepository;
        _subscriptionService = subscriptionService;
        _tenantContext = tenantContext;
        _cache = cache;
    }

    private int CurrentTenantId => _tenantContext.TenantId != 0 ? _tenantContext.TenantId : throw new UnauthorizedException("Tenant ID not found in context.");

    public async Task<Association?> GetByIdAsync(int id)
    {
        string cacheKey = $"association:{CurrentTenantId}:{id}";
        var cachedData = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedData))
        {
            return JsonSerializer.Deserialize<Association>(cachedData);
        }

        var association = await _associationRepository.GetByIdAsync(id, CurrentTenantId);
        if (association != null)
        {
            await _cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(association), new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30)
            });
        }

        return association;
    }

    public async Task<IEnumerable<Association>> GetAllByTenantAsync()
    {
        string cacheKey = $"associations:{CurrentTenantId}";
        var cachedData = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedData))
        {
            return JsonSerializer.Deserialize<IEnumerable<Association>>(cachedData) ?? new List<Association>();
        }

        var associations = await _associationRepository.GetAllByTenantIdAsync(CurrentTenantId);
        await _cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(associations), new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
        });

        return associations;
    }

    public async Task<IEnumerable<Association>> GetAllGlobalAsync()
    {
        string cacheKey = $"associations:global";
        var cachedData = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedData))
        {
            return JsonSerializer.Deserialize<IEnumerable<Association>>(cachedData) ?? new List<Association>();
        }

        var associations = await _associationRepository.GetAllAsync();
        await _cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(associations), new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
        });

        return associations;
    }

    public async Task<int> CreateAsync(Association association)
    {
        association.TenantId = CurrentTenantId;
        int id = await _associationRepository.CreateAsync(association);
        
        // Auto-subscribe to Starter Plan (ID: 1)
        await _subscriptionService.SubscribeAsync(id, 1);
        
        await InvalidateCache();
        return id;
    }

    public async Task<bool> UpdateAsync(Association association)
    {
        association.TenantId = CurrentTenantId;
        bool success = await _associationRepository.UpdateAsync(association);
        if (success)
        {
            await InvalidateCache(association.AssociationId);
        }
        return success;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        bool success = await _associationRepository.DeleteAsync(id, CurrentTenantId);
        if (success)
        {
            await InvalidateCache(id);
        }
        return success;
    }

    private async Task InvalidateCache(int? id = null)
    {
        await _cache.RemoveAsync($"associations:global");
        await _cache.RemoveAsync($"associations:{CurrentTenantId}");
        if (id.HasValue)
        {
            await _cache.RemoveAsync($"association:{CurrentTenantId}:{id.Value}");
        }
    }

    public async Task<IEnumerable<Association>> GetByUserIdAsync(int userId)
    {
        return await _associationRepository.GetByUserIdAsync(userId);
    }
}

public class UnauthorizedException : Exception
{
    public UnauthorizedException(string message) : base(message) { }
}
