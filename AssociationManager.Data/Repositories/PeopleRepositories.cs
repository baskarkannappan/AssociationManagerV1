using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class PersonRepository : IPersonRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public PersonRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<Person?> GetByIdAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Person>(
            "assoc.sp_Persons_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Person>> GetAllAsync(int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Person>(
            "assoc.sp_Persons_GetAll", 
            new { TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Person person)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Persons_Create", 
            new 
            { 
                person.TenantId, 
                person.AssociationId, 
                person.FirstName, 
                person.LastName, 
                person.Email, 
                person.Phone, 
                person.PhotoUrl, 
                person.CreatedDate, 
                person.IsActive 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Person person)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Persons_Update", 
            new 
            { 
                person.PersonId,
                person.TenantId, 
                person.AssociationId, 
                person.FirstName, 
                person.LastName, 
                person.Email, 
                person.Phone, 
                person.PhotoUrl, 
                person.IsActive 
            },
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Persons_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}

public class OccupancyRepository : IOccupancyRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public OccupancyRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<IEnumerable<Occupancy>> GetByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Occupancy>(
            "assoc.sp_Occupancy_GetByAssetId", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Occupancy>> GetByUserIdAsync(int userId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Occupancy>(
            "assoc.sp_Occupancy_GetByUserId", 
            new { UserId = userId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Occupancy?> GetByIdAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Occupancy>(
            "assoc.sp_Occupancy_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Occupancy occupancy)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Occupancy_Create", 
            new 
            { 
                occupancy.AssetId, 
                occupancy.PersonId, 
                occupancy.TenantId, 
                occupancy.AssociationId, 
                occupancy.OccupancyType, 
                occupancy.StartDate, 
                occupancy.EndDate, 
                occupancy.IsPrimaryContact 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int? associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Occupancy_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
