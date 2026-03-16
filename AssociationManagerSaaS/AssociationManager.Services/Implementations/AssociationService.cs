using System.Collections.Generic;
using System.Threading.Tasks;
using AssociationManager.Data.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Services.Interfaces;

namespace AssociationManager.Services.Implementations
{
    public class AssociationService : IAssociationService
    {
        private readonly IAssociationRepository _repository;

        public AssociationService(IAssociationRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<Association>> GetAssociationsAsync(int tenantId)
        {
            return await _repository.GetByTenantIdAsync(tenantId);
        }

        public async Task<Association?> GetAsync(int id, int tenantId)
        {
            return await _repository.GetByIdAsync(id, tenantId);
        }

        public async Task<int> CreateAsync(Association association)
        {
            return await _repository.CreateAsync(association);
        }

        public async Task UpdateAsync(Association association)
        {
            await _repository.UpdateAsync(association);
        }

        public async Task DeleteAsync(int id, int tenantId)
        {
            await _repository.DeleteAsync(id, tenantId);
        }
    }
}
