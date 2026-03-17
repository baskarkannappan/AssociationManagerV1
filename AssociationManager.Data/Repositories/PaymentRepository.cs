using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class PaymentRepository : IPaymentRepository
{
    private readonly DbConnectionFactory _dbConnectionFactory;
    private readonly ITenantContext _tenantContext;

    public PaymentRepository(DbConnectionFactory dbConnectionFactory, ITenantContext tenantContext)
    {
        _dbConnectionFactory = dbConnectionFactory;
        _tenantContext = tenantContext;
    }

    public async Task<Payment?> GetByIdAsync(int id, int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Payment>(
            "SELECT * FROM Payments WHERE PaymentId = @Id AND TenantId = @TenantId", 
            new { Id = id, TenantId = _tenantContext.TenantId });
    }

    public async Task<IEnumerable<Payment>> GetByTenantIdAsync(int tenantId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Payment>(
            "SELECT * FROM Payments WHERE TenantId = @TenantId", 
            new { TenantId = _tenantContext.TenantId });
    }

    public async Task<int> CreateAsync(Payment payment)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO Payments (TenantId, UserId, Amount, Currency, Status, CreatedDate, GatewayReference) " +
                     "OUTPUT INSERTED.PaymentId " +
                     "VALUES (@TenantId, @UserId, @Amount, @Currency, @Status, @CreatedDate, @GatewayReference)";
        return await connection.ExecuteScalarAsync<int>(sql, payment);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, string? gatewayReference)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE Payments SET Status = @Status, GatewayReference = @GatewayReference WHERE PaymentId = @Id";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, Status = status, GatewayReference = gatewayReference });
        return affectedRows > 0;
    }
}
