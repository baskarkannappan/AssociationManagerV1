using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class CommunicationRepository : ICommunicationRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public CommunicationRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<CommunicationLog?> GetByIdAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<CommunicationLog>(
            "assoc.sp_CommunicationLogs_GetById",
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<CommunicationLog>> GetByAssociationIdAsync(int tenantId, int associationId, int? status = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<CommunicationLog>(
            "assoc.sp_CommunicationLogs_GetByAssociation",
            new { TenantId = tenantId, AssociationId = associationId, Status = status },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<CommunicationLog>> GetPendingEmailsAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<CommunicationLog>(
            "assoc.sp_CommunicationLogs_GetPending",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(CommunicationLog log)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_CommunicationLogs_Create",
            new
            {
                log.TenantId,
                log.AssociationId,
                log.RecipientEmail,
                log.RecipientName,
                log.Subject,
                log.HtmlBody,
                log.ReferenceType,
                log.ReferenceId,
                Status = (int)log.Status,
                log.ScheduledDate
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateStatusAsync(int id, int tenantId, int status, string? errorMessage = null)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_CommunicationLogs_UpdateStatus",
            new { Id = id, TenantId = tenantId, Status = status, ErrorMessage = errorMessage },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
