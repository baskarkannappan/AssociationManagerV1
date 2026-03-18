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

    public async Task<Payment?> GetByIdAsync(int id, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Payment>(
            "SELECT * FROM Payments WHERE PaymentId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId", 
            new { Id = id, TenantId = tenantId, AssociationId = associationId });
    }

    public async Task<IEnumerable<Payment>> GetByTenantIdAsync(int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        return await connection.QueryAsync<Payment>(
            "SELECT * FROM Payments WHERE TenantId = @TenantId AND AssociationId = @AssociationId", 
            new { TenantId = tenantId, AssociationId = associationId });
    }

    public async Task<int> CreateAsync(Payment payment)
    {
        payment.TenantId = _tenantContext.TenantId;
        payment.AssociationId = _tenantContext.AssociationId;
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "INSERT INTO Payments (TenantId, AssociationId, UserId, Amount, Currency, Status, CreatedDate, GatewayReference) " +
                     "OUTPUT INSERTED.PaymentId " +
                     "VALUES (@TenantId, @AssociationId, @UserId, @Amount, @Currency, @Status, @CreatedDate, @GatewayReference)";
        return await connection.ExecuteScalarAsync<int>(sql, payment);
    }

    public async Task<bool> UpdateStatusAsync(int id, string status, string? gatewayReference, int tenantId, int associationId)
    {
        using var connection = _dbConnectionFactory.CreateConnection();
        string sql = "UPDATE Payments SET Status = @Status, GatewayReference = @GatewayReference WHERE PaymentId = @Id AND TenantId = @TenantId AND AssociationId = @AssociationId";
        int affectedRows = await connection.ExecuteAsync(sql, new { Id = id, Status = status, GatewayReference = gatewayReference, TenantId = tenantId, AssociationId = associationId });
        return affectedRows > 0;
    }
}
