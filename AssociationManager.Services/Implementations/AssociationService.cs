using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class AssociationService : IAssociationService
{
    private readonly IAssociationRepository _associationRepository;
    private readonly IAssocUserRepository _assocUserRepository;
    private readonly ITenantContext _tenantContext;
    private readonly IDistributedCache _cache;
    private readonly ILogger<AssociationService> _logger;

    public AssociationService(
        IAssociationRepository associationRepository,
        IAssocUserRepository assocUserRepository,
        ITenantContext tenantContext,
        IDistributedCache cache,
        ILogger<AssociationService> logger)
    {
        _associationRepository = associationRepository;
        _assocUserRepository = assocUserRepository;
        _tenantContext = tenantContext;
        _cache = cache;
        _logger = logger;
    }

    private int CurrentTenantId => _tenantContext.TenantId;

    public async Task<Association?> GetByIdAsync(int id)
    {
        return await _associationRepository.GetByIdAsync(id, CurrentTenantId);
    }

    public async Task<IEnumerable<Association>> GetAllGlobalAsync()
    {
        return await _associationRepository.GetAllAsync();
    }

    public async Task<IEnumerable<Association>> GetAllByTenantAsync()
    {
        return await _associationRepository.GetAllByTenantIdAsync(CurrentTenantId);
    }

    public async Task<IEnumerable<Association>> GetByUserIdAsync(int userId)
    {
        return await _associationRepository.GetByUserIdAsync(userId);
    }

    public async Task<int> CreateAsync(Association association)
    {
        association.TenantId = CurrentTenantId;
        association.CreatedDate = DateTime.UtcNow;
        
        var id = await _associationRepository.CreateAsync(association);

        // Logic for provisioning Association Admin
        if (!string.IsNullOrEmpty(association.AdminEmail))
        {
            var adminEmail = association.AdminEmail.Trim();
            var user = await _assocUserRepository.GetByEmailAsync(adminEmail);
            int userId;
            if (user == null)
            {
                // Create user if they don't exist in assoc schema
                userId = await _assocUserRepository.CreateAsync(new User
                {
                    Email = adminEmail,
                    Name = adminEmail.Split('@')[0], // Default name from email
                    Role = "AssociationAdmin", // Provision as AssociationAdmin
                    CreatedDate = DateTime.UtcNow,
                    IsActive = true
                });
            }
            else
            {
                userId = user.UserId;
            }

            // Map user to association as AssociationAdmin
            await _assocUserRepository.AddUserToTenantAsync(userId, id, "AssociationAdmin");
        }
        
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
        // First delete mappings in assoc schema to avoid FK constraint issues
        await _assocUserRepository.DeleteByAssociationIdAsync(id);
        
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
}
