using System.Collections.Generic;
using System.Threading.Tasks;
using Dapper;
using AssociationManager.Shared.Models;
using AssociationManager.Data.Interfaces;

namespace AssociationManager.Data.Repositories
{
    public class PaymentRepository : IPaymentRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public PaymentRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<int> CreateAsync(Payment payment)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sql = "INSERT INTO Payments (TenantId, Amount, Currency, Status, ExternalId) VALUES (@TenantId, @Amount, @Currency, @Status, @ExternalId); SELECT CAST(SCOPE_IDENTITY() as int)";
            return await connection.ExecuteScalarAsync<int>(sql, payment);
        }

        public async Task<IEnumerable<Payment>> GetByTenantIdAsync(int tenantId)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryAsync<Payment>("SELECT * FROM Payments WHERE TenantId = @TenantId ORDER BY CreatedAt DESC", new { TenantId = tenantId });
        }

        public async Task<Payment?> GetByIdAsync(int id, int tenantId)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<Payment>("SELECT * FROM Payments WHERE Id = @Id AND TenantId = @TenantId", new { Id = id, TenantId = tenantId });
        }

        public async Task UpdateStatusAsync(int id, string status)
        {
            using var connection = _connectionFactory.CreateConnection();
            await connection.ExecuteAsync("UPDATE Payments SET Status = @Status, UpdatedAt = GETUTCDATE() WHERE Id = @Id", new { Id = id, Status = status });
        }
    }
}
