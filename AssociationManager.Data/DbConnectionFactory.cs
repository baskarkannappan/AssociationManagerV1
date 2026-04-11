using AssociationManager.Shared.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace AssociationManager.Data;

public class DbConnectionFactory
{
    private readonly IConfiguration _configuration;
    private readonly ITenantContext _tenantContext;
    private readonly string _connectionString;

    public DbConnectionFactory(IConfiguration configuration, ITenantContext tenantContext)
    {
        _configuration = configuration;
        _tenantContext = tenantContext;
        _connectionString = _configuration.GetConnectionString("DefaultConnection") 
            ?? throw new System.Exception("Connection string 'DefaultConnection' not found.");
    }

    /// <summary>
    /// Creates and opens a database connection, automatically setting the SESSION_CONTEXT
    /// for Row-Level Security isolation.
    /// </summary>
    public IDbConnection CreateConnection()
    {
        var connection = new SqlConnection(_connectionString);
        
        // We open the connection immediately to set the session context.
        // This ensures Row-Level Security is active before any repository query runs.
        connection.Open();

        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            EXEC sp_set_session_context @key=N'TenantId', @value=@TenantId; 
            EXEC sp_set_session_context @key=N'IsAdmin', @value=@IsAdmin;";
        
        var pTenant = cmd.CreateParameter();
        pTenant.ParameterName = "@TenantId";
        pTenant.Value = _tenantContext.TenantId;
        cmd.Parameters.Add(pTenant);

        var pAdmin = cmd.CreateParameter();
        pAdmin.ParameterName = "@IsAdmin";
        pAdmin.Value = _tenantContext.IsSystemAdmin ? 1 : 0;
        cmd.Parameters.Add(pAdmin);

        cmd.ExecuteNonQuery();

        return connection;
    }
}
