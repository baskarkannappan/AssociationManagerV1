using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface IAuthWorkflowRepository
{
    Task<AuthWorkflow?> GetByNameAsync(string name);
    Task<bool> UpsertAsync(AuthWorkflow workflow);
    Task<IEnumerable<AuthWorkflow>> GetAllAsync();
}

public class AuthWorkflow
{
    public int WorkflowId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string WorkflowJson { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime UpdatedDate { get; set; }
}
