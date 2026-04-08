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
    private readonly IGlobalUserRepository _globalUserRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly ITenantContext _tenantContext;
    private readonly IDistributedCache _cache;
    private readonly ILogger<AssociationService> _logger;
    public AssociationService(
        IAssociationRepository associationRepository,
        IAssocUserRepository assocUserRepository,
        IGlobalUserRepository globalUserRepository,
        ITenantRepository tenantRepository,
        ITenantContext tenantContext,
        IDistributedCache cache,
        ILogger<AssociationService> logger)
    {
        _associationRepository = associationRepository;
        _assocUserRepository = assocUserRepository;
        _globalUserRepository = globalUserRepository;
        _tenantRepository = tenantRepository;
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
        // Option B Implementation: Each Association is a separate Tenant
        // 1. Create the Tenant First
        var tenantId = await _tenantRepository.CreateAsync(new Tenant 
        { 
            Name = association.Name,
            CreatedDate = DateTime.UtcNow,
            IsActive = true
        });

        // 2. Link the Association to the new Tenant
        association.TenantId = tenantId;
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

            // Two-Level Mapping for Option B (Standalone Associations):
            
            // 1. GLOBAL LEVEL: Map user to the brand new Tenant (for corporate/billing context)
            await _globalUserRepository.AddUserToTenantAsync(userId, tenantId, "AssociationAdmin");

            // 2. LOCAL LEVEL: Map user to the brand new Association (for resident/asset management)
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
        // For deactivation, we DO NOT delete mappings as we want the Association Admin
        // to still have Read-Only access.
        
        bool success = await _associationRepository.DeleteAsync(id, CurrentTenantId);
        if (success)
        {
            await InvalidateCache(id);
        }
        return success;
    }

    public async Task<bool> UpdateStatusAsync(int id, string status)
    {
        bool success = await _associationRepository.UpdateStatusAsync(id, status);
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
