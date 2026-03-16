using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;

namespace AssociationManager.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class AssociationsController : ControllerBase
    {
        private readonly IAssociationService _associationService;

        public AssociationsController(IAssociationService associationService)
        {
            _associationService = associationService;
        }

        private int GetTenantId() => (int)HttpContext.Items["TenantId"]!;

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var associations = await _associationService.GetAssociationsAsync(GetTenantId());
            return Ok(associations);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var association = await _associationService.GetAsync(id, GetTenantId());
            if (association == null) return NotFound();
            return Ok(association);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Association association)
        {
            association.TenantId = GetTenantId();
            var id = await _associationService.CreateAsync(association);
            association.Id = id;
            return CreatedAtAction(nameof(GetById), new { id }, association);
        }
    }
}
