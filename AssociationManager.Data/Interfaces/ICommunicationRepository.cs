using AssociationManager.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Data.Interfaces;

public interface ICommunicationRepository
{
    Task<CommunicationLog?> GetByIdAsync(int id, int tenantId, int? associationId);
    Task<IEnumerable<CommunicationLog>> GetByAssociationIdAsync(int tenantId, int associationId, int? status = null);
    Task<IEnumerable<CommunicationLog>> GetPendingEmailsAsync();
    Task<int> CreateAsync(CommunicationLog log);
    Task<bool> UpdateStatusAsync(int id, int tenantId, int status, string? errorMessage = null);
}
