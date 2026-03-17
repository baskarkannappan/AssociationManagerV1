using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class VehicleRepository : IVehicleRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public VehicleRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<IEnumerable<Vehicle>> GetByAssetIdAsync(int assetId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Vehicle>(
            "SELECT * FROM Vehicles WHERE AssetId = @AssetId AND TenantId = @TenantId AND IsActive = 1", 
            new { AssetId = assetId, TenantId = tenantId });
    }

    public async Task<int> CreateAsync(Vehicle vehicle)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            INSERT INTO Vehicles (AssetId, TenantId, Make, Model, LicensePlate, Color, ParkingSlot, IsActive)
            OUTPUT INSERTED.VehicleId
            VALUES (@AssetId, @TenantId, @Make, @Model, @LicensePlate, @Color, @ParkingSlot, @IsActive)";
        return await connection.ExecuteScalarAsync<int>(sql, vehicle);
    }

    public async Task<bool> UpdateAsync(Vehicle vehicle)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            UPDATE Vehicles SET Make = @Make, Model = @Model, LicensePlate = @LicensePlate, 
                               Color = @Color, ParkingSlot = @ParkingSlot, IsActive = @IsActive 
            WHERE VehicleId = @VehicleId AND TenantId = @TenantId";
        return await connection.ExecuteAsync(sql, vehicle) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "UPDATE Vehicles SET IsActive = 0 WHERE VehicleId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = tenantId }) > 0;
    }
}

public class PetRepository : IPetRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    public PetRepository(DbConnectionFactory dbConnectionFactory) => _dbConnectionFactory = dbConnectionFactory;

    public async Task<IEnumerable<Pet>> GetByAssetIdAsync(int assetId, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Pet>(
            "SELECT * FROM Pets WHERE AssetId = @AssetId AND TenantId = @TenantId AND IsActive = 1", 
            new { AssetId = assetId, TenantId = tenantId });
    }

    public async Task<int> CreateAsync(Pet pet)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            INSERT INTO Pets (AssetId, TenantId, Name, Species, Breed, TagNumber, IsActive)
            OUTPUT INSERTED.PetId
            VALUES (@AssetId, @TenantId, @Name, @Species, @Breed, @TagNumber, @IsActive)";
        return await connection.ExecuteScalarAsync<int>(sql, pet);
    }

    public async Task<bool> UpdateAsync(Pet pet)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"
            UPDATE Pets SET Name = @Name, Species = @Species, Breed = @Breed, 
                            TagNumber = @TagNumber, IsActive = @IsActive 
            WHERE PetId = @PetId AND TenantId = @TenantId";
        return await connection.ExecuteAsync(sql, pet) > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.ExecuteAsync(
            "UPDATE Pets SET IsActive = 0 WHERE PetId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = tenantId }) > 0;
    }
}
