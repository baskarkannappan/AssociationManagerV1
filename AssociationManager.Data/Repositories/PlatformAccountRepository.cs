using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class PlatformAccountRepository : IPlatformAccountRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public PlatformAccountRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<PlatformAccount?> GetByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<PlatformAccount>(
            "corp.sp_PlatformAccounts_GetById", 
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<PlatformAccount>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<PlatformAccount>(
            "corp.sp_PlatformAccounts_List",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(PlatformAccount account)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_PlatformAccounts_Create", 
            new 
            { 
                account.AccountName, 
                account.AccountNumber, 
                account.BankName, 
                account.IFSCCode,
                account.BranchName,
                account.RazorpayKeyId,
                account.RazorpayKeySecret,
                account.IsActive 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(PlatformAccount account)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_PlatformAccounts_Update", 
            new 
            { 
                account.Id,
                account.AccountName, 
                account.AccountNumber, 
                account.BankName, 
                account.IFSCCode,
                account.BranchName,
                account.RazorpayKeyId,
                account.RazorpayKeySecret,
                account.IsActive 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "corp.sp_PlatformAccounts_Delete", 
            new { Id = id },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
