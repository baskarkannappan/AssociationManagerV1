using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IContentRepository
{
    Task<StaticContent?> GetStaticContentAsync(string key);
    Task<bool> UpsertStaticContentAsync(StaticContent content);
    Task<int> CreateSupportQueryAsync(SupportQuery query);
    Task<IEnumerable<SupportQuery>> GetAllSupportQueriesAsync();
}
