using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class BroadcastRepository : IBroadcastRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;


    public BroadcastRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Broadcast?> GetByIdAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Broadcast>(
            "assoc.sp_Broadcasts_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Broadcast>> GetAllAsync(int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Broadcast>(
            "assoc.sp_Broadcasts_GetAll", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Broadcast>> GetByAssetIdAsync(int assetId, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Broadcast>(
            "assoc.sp_Broadcasts_GetByAssetId", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Broadcast broadcast)
    {
        broadcast.TenantId = _tenantContext.TenantId;
        broadcast.AssociationId = _tenantContext.AssociationId;
        broadcast.CreatedBy = _tenantContext.UserId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Broadcasts_Create", 
            new 
            { 
                broadcast.TenantId, 
                broadcast.AssociationId, 
                broadcast.Title, 
                broadcast.Content, 
                broadcast.Category, 
                broadcast.CreatedDate, 
                broadcast.CreatedBy, 
                broadcast.IsPinned, 
                broadcast.ExpiresDate, 
                broadcast.AssetId 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Broadcasts_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
