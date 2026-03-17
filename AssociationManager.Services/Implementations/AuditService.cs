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

    public async Task LogAsync(string action, string? entity = null, int? entityId = null)
    {
        var tenantId = _tenantContext.TenantId;
        if (tenantId == 0) return;

        var userId = _tenantContext.UserId;
        
        var log = new AuditLog
        {
            TenantId = tenantId,
            UserId = userId != 0 ? userId : null,
            Action = action,
            Entity = entity,
            EntityId = entityId,
            IpAddress = _httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString(),
            Timestamp = DateTime.UtcNow
        };

        await _auditLogRepository.CreateAsync(log);
    }

    public async Task<IEnumerable<AuditLog>> GetLogsAsync()
    {
        var tenantId = _tenantContext.TenantId;
        if (tenantId == 0) return new List<AuditLog>();

        return await _auditLogRepository.GetByTenantIdAsync(tenantId);
    }
}
