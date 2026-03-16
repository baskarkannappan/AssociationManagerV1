using System;
using System.Collections.Generic;
using AssociationManager.Shared.DTOs;

namespace AssociationManager.Client.Services
{
    public class TenantService
    {
        public event Action? OnTenantChanged;
        public TenantDto? CurrentTenant { get; private set; }
        public List<TenantDto> AvailableTenants { get; set; } = new();

        public void SetTenant(TenantDto tenant)
        {
            CurrentTenant = tenant;
            OnTenantChanged?.Invoke();
        }

        public void SetTenants(List<TenantDto> tenants)
        {
            AvailableTenants = tenants;
        }
    }
}
