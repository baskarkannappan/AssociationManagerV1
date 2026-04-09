using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Interfaces;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class AuditService : IAuditService
{
    private readonly IAuditLogRepository _auditLogRepository;
    private readonly ITenantContext _tenantContext;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditService(
        IAuditLogRepository auditLogRepository,
        ITenantContext tenantContext,
        IHttpContextAccessor httpContextAccessor)
    {
        _auditLogRepository = auditLogRepository;
        _tenantContext = tenantContext;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task LogAsync(string action, string? entity = null, int? entityId = null, int? associationId = null, int? assetId = null, int? tenantId = null)
    {
        var targetTenantId = tenantId != null && tenantId != 0 ? tenantId : _tenantContext.TenantId;
        if (targetTenantId == 0) return; // Still require a tenant for DB constraints

        var targetAssociationId = associationId != null && associationId != 0 ? associationId : _tenantContext.AssociationId;
        var userId = _tenantContext.UserId;
        
        var log = new AuditLog
        {
            TenantId = targetTenantId.Value,
            AssociationId = targetAssociationId != 0 ? targetAssociationId : null,
            UserId = userId != 0 ? userId : null,
            AssetId = assetId != 0 ? assetId : null,
            Action = action,
            Entity = entity,
            EntityId = entityId != 0 ? entityId : null,
            IpAddress = _httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString(),
            Timestamp = DateTime.UtcNow
        };

        await _auditLogRepository.CreateAsync(log);
    }

    public async Task<IEnumerable<AuditLog>> GetLogsAsync()
    {
        var tenantId = _tenantContext.TenantId;
        var associationId = _tenantContext.AssociationId;
        if (tenantId == 0) return new List<AuditLog>();

        return await _auditLogRepository.GetByTenantIdAsync(tenantId, associationId);
    }

    public async Task<IEnumerable<AuditLog>> GetAssetLogsAsync(int assetId)
    {
        var tenantId = _tenantContext.TenantId;
        var associationId = _tenantContext.AssociationId;
        return await _auditLogRepository.GetByAssetIdAsync(assetId, tenantId, associationId);
    }
}
