using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class AuditService : IAuditService
{
    private readonly IAuditLogRepository _auditLogRepository;
    private readonly ITenantAccessor _tenantAccessor;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditService(
        IAuditLogRepository auditLogRepository,
        ITenantAccessor tenantAccessor,
        IHttpContextAccessor httpContextAccessor)
    {
        _auditLogRepository = auditLogRepository;
        _tenantAccessor = tenantAccessor;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task LogAsync(string action, string? entity = null, int? entityId = null)
    {
        var tenantId = _tenantAccessor.TenantId;
        if (tenantId == null) return;

        var userIdStr = _httpContextAccessor.HttpContext?.User?.FindFirst("UserId")?.Value;
        int? userId = int.TryParse(userIdStr, out int val) ? val : null;

        var log = new AuditLog
        {
            TenantId = tenantId.Value,
            UserId = userId,
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
        var tenantId = _tenantAccessor.TenantId;
        if (tenantId == null) return new List<AuditLog>();

        return await _auditLogRepository.GetByTenantIdAsync(tenantId.Value);
    }
}
