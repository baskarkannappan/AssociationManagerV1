using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class AssociationRepository : IAssociationRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;
    private readonly string _schema;

    public AssociationRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext, string schema = "corp")
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
        _schema = schema;
    }

    public async Task<Association?> GetByIdAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Association>(
            "corp.sp_Associations_GetById", 
            new { Id = id, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Association>> GetAllByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            "corp.sp_Associations_GetAllByTenantId", 
            new { TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Association association)
    {
        association.TenantId = _tenantContext.TenantId;
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_Associations_Create", 
            new 
            { 
                association.TenantId, 
                association.Name, 
                association.Description, 
                association.CreatedDate, 
                association.CreatedBy,
                association.AdminEmail,
                association.PlatformAccountId,
                association.AdminPaysFee
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Association association)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Associations_Update", 
            new 
            { 
                association.AssociationId, 
                association.TenantId, 
                association.Name, 
                association.Description,
                association.AdminEmail,
                association.PlatformAccountId,
                association.AdminPaysFee,
                association.Status
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Associations_Delete", 
            new { Id = id, TenantId = tenantId },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<Association>> GetByUserIdAsync(int userId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            $"{_schema}.sp_Associations_GetByUserId", 
            new { UserId = userId },
            commandType: CommandType.StoredProcedure);
    }
    
    public async Task<bool> UpdateStatusAsync(int id, string status)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_Associations_UpdateStatus", 
            new { Id = id, Status = status },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<IEnumerable<Association>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Association>(
            "corp.sp_Associations_List",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<AssociationBankDetails?> GetBankDetailsAsync(int associationId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<AssociationBankDetails>(
            "assoc.sp_AssociationBankDetails_Get",
            new { AssociationId = associationId, TenantId = tenantId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpsertBankDetailsAsync(AssociationBankDetails details)
    {
        if (details.AssociationId <= 0) 
            throw new ArgumentException("Invalid AssociationId for bank details.");

        using var connection = _dbConnectionFactory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AssociationId", details.AssociationId, DbType.Int32);
        parameters.Add("@TenantId", details.TenantId, DbType.Int32);
        parameters.Add("@PrimaryAccountName", details.PrimaryAccountName, DbType.String, size: 255);
        parameters.Add("@PrimaryAccountNumber", details.PrimaryAccountNumber, DbType.String, size: 50);
        parameters.Add("@PrimaryIFSCCode", details.PrimaryIFSCCode, DbType.String, size: 20);
        parameters.Add("@PrimaryBankName", details.PrimaryBankName, DbType.String, size: 255);
        parameters.Add("@PrimaryBranchName", details.PrimaryBranchName, DbType.String, size: 255);
        
        // Explicitly set type to Binary for VARBINARY(MAX) fields
        parameters.Add("@PrimaryQRCode", details.PrimaryQRCode, DbType.Binary, size: -1);
        parameters.Add("@PrimaryQRCodeContentType", details.PrimaryQRCodeContentType, DbType.String, size: 100);
        
        parameters.Add("@SecondaryAccountName", details.SecondaryAccountName, DbType.String, size: 255);
        parameters.Add("@SecondaryAccountNumber", details.SecondaryAccountNumber, DbType.String, size: 50);
        parameters.Add("@SecondaryIFSCCode", details.SecondaryIFSCCode, DbType.String, size: 20);
        parameters.Add("@SecondaryBankName", details.SecondaryBankName, DbType.String, size: 255);
        parameters.Add("@SecondaryBranchName", details.SecondaryBranchName, DbType.String, size: 255);
        
        parameters.Add("@SecondaryQRCode", details.SecondaryQRCode, DbType.Binary, size: -1);
        parameters.Add("@SecondaryQRCodeContentType", details.SecondaryQRCodeContentType, DbType.String, size: 100);
        
        parameters.Add("@UserId", _tenantContext.UserId, DbType.Int32);

        await connection.ExecuteAsync("assoc.sp_AssociationBankDetails_Upsert", parameters, commandType: CommandType.StoredProcedure);
        return true;
    }
}
