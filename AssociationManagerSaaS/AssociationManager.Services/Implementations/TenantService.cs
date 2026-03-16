using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Services.Interfaces;

namespace AssociationManager.Services.Implementations
{
    public class TenantService : ITenantService
    {
        private readonly ITenantRepository _tenantRepository;
        private readonly ICacheService _cacheService;

        public TenantService(ITenantRepository tenantRepository, ICacheService cacheService)
        {
            _tenantRepository = tenantRepository;
            _cacheService = cacheService;
        }

        public async Task<Tenant?> GetByIdAsync(int id)
        {
            string cacheKey = $"tenant_{id}";
            var cached = await _cacheService.GetAsync<Tenant>(cacheKey);
            if (cached != null) return cached;

            var tenant = await _tenantRepository.GetByIdAsync(id);
            if (tenant != null)
            {
                await _cacheService.SetAsync(cacheKey, tenant, TimeSpan.FromHours(1));
            }
            return tenant;
        }

        public async Task<Tenant?> GetByIdentifierAsync(string identifier)
        {
            string cacheKey = $"tenant_ident_{identifier}";
            var cached = await _cacheService.GetAsync<Tenant>(cacheKey);
            if (cached != null) return cached;

            var tenant = await _tenantRepository.GetByIdentifierAsync(identifier);
            if (tenant != null)
            {
                await _cacheService.SetAsync(cacheKey, tenant, TimeSpan.FromHours(1));
            }
            return tenant;
        }

        public async Task<IEnumerable<Tenant>> GetAllActiveAsync()
        {
            return await _tenantRepository.GetAllAsync();
        }

        public async Task<int> CreateTenantAsync(Tenant tenant)
        {
            var id = await _tenantRepository.CreateAsync(tenant);
            return id;
        }

        public async Task<IEnumerable<Tenant>> GetUserTenantsAsync(int userId)
        {
            return await _tenantRepository.GetByUserIdAsync(userId);
        }
    }
}
