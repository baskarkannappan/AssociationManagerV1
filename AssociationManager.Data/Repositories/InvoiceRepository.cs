using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class InvoiceRepository : IInvoiceRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public InvoiceRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Invoice?> GetByIdAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Invoice>(
            @"SELECT i.*, a.Name as AssetName 
              FROM Invoices i 
              LEFT JOIN Assets a ON i.AssetId = a.AssetId
              WHERE i.InvoiceId = @Id AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId });
    }

    public async Task<IEnumerable<Invoice>> GetAllAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Invoice>(
            @"SELECT i.*, a.Name as AssetName 
              FROM Invoices i 
              LEFT JOIN Assets a ON i.AssetId = a.AssetId
              WHERE i.TenantId = @TenantId AND i.AssociationId = @AssociationId
              ORDER BY i.DueDate DESC", 
            new { TenantId = tenantId, AssociationId = associationId });
    }

    public async Task<IEnumerable<Invoice>> GetByAssetIdAsync(int assetId, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Invoice>(
            @"SELECT i.*, a.Name as AssetName 
              FROM Invoices i 
              LEFT JOIN Assets a ON i.AssetId = a.AssetId
              WHERE i.AssetId = @AssetId AND i.TenantId = @TenantId AND i.AssociationId = @AssociationId
              ORDER BY i.DueDate DESC", 
            new { AssetId = assetId, TenantId = tenantId, AssociationId = associationId });
    }

    public async Task<int> CreateAsync(Invoice invoice)
    {
        invoice.TenantId = _tenantContext.TenantId;
        invoice.AssociationId = _tenantContext.AssociationId;
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = @"INSERT INTO Invoices (TenantId, AssociationId, AssetId, Title, Description, Amount, DueDate, Status, CreatedDate) 
                       OUTPUT INSERTED.InvoiceId 
                       VALUES (@TenantId, @AssociationId, @AssetId, @Title, @Description, @Amount, @DueDate, @Status, @CreatedDate)";
        return await connection.ExecuteScalarAsync<int>(sql, invoice);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE Invoices SET Status = @Status WHERE InvoiceId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, Status = status, TenantId = tenantId, AssociationId = associationId });
        return affectedRows > 0;
    }

    public async Task<bool> DeleteAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "DELETE FROM Invoices WHERE InvoiceId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, TenantId = tenantId, AssociationId = associationId });
        return affectedRows > 0;
    }
}
