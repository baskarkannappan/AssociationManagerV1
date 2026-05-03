using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace AssociationManager.Data.Repositories;

public class ContentRepository : IContentRepository
{
    private readonly DbConnectionFactory _connectionFactory;

    public ContentRepository(DbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<StaticContent?> GetStaticContentAsync(string key)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<StaticContent>(
            "corp.sp_StaticContent_GetByKey",
            new { ContentKey = key },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> UpsertStaticContentAsync(StaticContent content)
    {
        using var connection = _connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "corp.sp_StaticContent_Upsert",
            new
            {
                content.ContentKey,
                content.Title,
                content.HtmlContent,
                content.UpdatedBy
            },
            commandType: CommandType.StoredProcedure);
        return true;
    }

    public async Task<int> CreateSupportQueryAsync(SupportQuery query)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "corp.sp_SupportQueries_Create",
            new
            {
                query.UserId,
                query.Name,
                query.Email,
                query.Subject,
                query.MessageBody
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<SupportQuery>> GetAllSupportQueriesAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryAsync<SupportQuery>(
            "corp.sp_SupportQueries_GetAll",
            commandType: CommandType.StoredProcedure);
    }
}
