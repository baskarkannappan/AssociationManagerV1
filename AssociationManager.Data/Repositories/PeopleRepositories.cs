using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class PersonRepository : IPersonRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public PersonRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<Person?> GetByIdAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Person>(
            "SELECT * FROM Persons WHERE PersonId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = tenantId });
    }

    public async Task<IEnumerable<Person>> GetAllAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Person>(
            "SELECT * FROM Persons WHERE TenantId = @TenantId AND IsActive = 1", 
            new { TenantId = tenantId });
    }

    public async Task<int> CreateAsync(Person person)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            INSERT INTO Persons (TenantId, FirstName, LastName, Email, Phone, PhotoUrl, CreatedDate, IsActive)
            OUTPUT INSERTED.PersonId
            VALUES (@TenantId, @FirstName, @LastName, @Email, @Phone, @PhotoUrl, @CreatedDate, @IsActive)";
        return await connection.ExecuteScalarAsync<int>(sql, person);
    }

    public async Task<bool> UpdateAsync(Person person)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            UPDATE Persons SET FirstName = @FirstName, LastName = @LastName, Email = @Email, 
                               Phone = @Phone, PhotoUrl = @PhotoUrl, IsActive = @IsActive 
            WHERE PersonId = @PersonId AND TenantId = @TenantId";
        return await connection.ExecuteAsync(sql, person) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "UPDATE Persons SET IsActive = 0 WHERE PersonId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = tenantId }) > 0;
    }
}

public class OccupancyRepository : IOccupancyRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public OccupancyRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<IEnumerable<Occupancy>> GetByAssetIdAsync(int assetId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Occupancy>(
            "SELECT * FROM Occupancy WHERE AssetId = @AssetId AND TenantId = @TenantId", 
            new { AssetId = assetId, TenantId = tenantId });
    }

    public async Task<int> CreateAsync(Occupancy occupancy)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            INSERT INTO Occupancy (AssetId, PersonId, TenantId, OccupancyType, StartDate, EndDate, IsPrimaryContact)
            OUTPUT INSERTED.OccupancyId
            VALUES (@AssetId, @PersonId, @TenantId, @OccupancyType, @StartDate, @EndDate, @IsPrimaryContact)";
        return await connection.ExecuteScalarAsync<int>(sql, occupancy);
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "DELETE FROM Occupancy WHERE OccupancyId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = tenantId }) > 0;
    }
}
