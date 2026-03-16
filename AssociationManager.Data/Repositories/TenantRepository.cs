using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class TenantRepository : ITenantRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;

    public TenantRepository(DbConnectionFactory dbConnectionFactory)
    {
        _dbConnectionFactory = dbConnectionFactory;
    }

    public async Task<Tenant?> GetByIdAsync(int id)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Tenant>(
            "SELECT * FROM Tenants WHERE TenantId = @Id", new { Id = id });
    }

    public async Task<IEnumerable<Tenant>> GetAllAsync()
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Tenant>("SELECT * FROM Tenants");
    }

    public async Task<int> CreateAsync(Tenant tenant)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO Tenants (Name, CreatedDate, IsActive) " +
                     "OUTPUT INSERTED.TenantId " +
                     "VALUES (@Name, @CreatedDate, @IsActive)";
        return await connection.ExecuteScalarAsync<int>(sql, tenant);
    }

    public async Task<bool> UpdateAsync(Tenant tenant)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE Tenants SET Name = @Name, IsActive = @IsActive WHERE TenantId = @TenantId";
        int affectedRows = await connection.ExecuteAsync(sql, tenant);
        return affectedRows > 0;
    }
}
