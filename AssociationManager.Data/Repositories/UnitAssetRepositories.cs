using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class VehicleRepository : IVehicleRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public VehicleRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<IEnumerable<Vehicle>> GetByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Vehicle>(
            "assoc.sp_Vehicles_GetByAssetId", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Vehicle?> GetByIdAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Vehicle>(
            "assoc.sp_Vehicles_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Vehicle vehicle)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Vehicles_Create", 
            new 
            { 
                vehicle.AssetId, 
                vehicle.TenantId, 
                vehicle.AssociationId, 
                vehicle.Make, 
                vehicle.Model, 
                vehicle.LicensePlate, 
                vehicle.Color, 
                vehicle.ParkingSlot, 
                vehicle.IsActive 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Vehicle vehicle)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Vehicles_Update", 
            vehicle,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Vehicles_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}

public class PetRepository : IPetRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public PetRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<IEnumerable<Pet>> GetByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Pet>(
            "assoc.sp_Pets_GetByAssetId", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Pet?> GetByIdAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Pet>(
            "assoc.sp_Pets_GetById", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> CreateAsync(Pet pet)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "assoc.sp_Pets_Create", 
            new 
            { 
                pet.AssetId, 
                pet.TenantId, 
                pet.AssociationId, 
                pet.Name, 
                pet.Species, 
                pet.Breed, 
                pet.TagNumber, 
                pet.IsActive 
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateAsync(Pet pet)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Pets_Update", 
            pet,
            commandType: CommandType.StoredProcedure) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "assoc.sp_Pets_Delete", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId },
            commandType: CommandType.StoredProcedure) > 0;
    }
}
