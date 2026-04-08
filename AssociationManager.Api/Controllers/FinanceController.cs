using AssociationManager.Shared.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace AssociationManager.Api.Controllers;

[Authorize]
[Authorize(Policy = "RequireResident")]
[ApiController]
[Route("api/[controller]")]
public class FinanceController : ControllerBase
{
    private readonly IFinanceService _financeService;
    private readonly IAuditService _auditService;
    private readonly ITenantContext _tenantContext;
    private readonly IPeopleService _peopleService;
    private readonly AssociationManager.Api.Services.Billing.BillingBatchService _batchService;
    private readonly IRuleEngineService _ruleEngine;
    private readonly IFineService _fineService;

    public FinanceController(
        IFinanceService financeService, 
        IAuditService auditService,
        ITenantContext tenantContext,
        IPeopleService peopleService,
        AssociationManager.Api.Services.Billing.BillingBatchService batchService,
        IRuleEngineService ruleEngine,
        IFineService fineService)
    {
        _financeService = financeService;
        _auditService = auditService;
        _tenantContext = tenantContext;
        _peopleService = peopleService;
        _batchService = batchService;
        _ruleEngine = ruleEngine;
        _fineService = fineService;
    }

    [HttpPost("batch-generate")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GenerateBatch([FromBody] InvoiceBatchRequest request)
    {
        var result = await _batchService.ProcessBatchAsync(request, _tenantContext.TenantId);
        return Ok(ApiResponse<InvoiceBatchResult>.SuccessResponse(result));
    }

    [HttpGet("invoices")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetInvoices(
        [FromQuery] int? associationId = null, 
        [FromQuery] int? assetId = null,
        [FromQuery] string? searchTerm = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string sortColumn = "CreatedDate",
        [FromQuery] string sortDirection = "DESC")
    {
        var roles = User.Claims.Where(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                              .Select(c => c.Value);

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roles),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId,
            Action = "View",
            Resource = "Invoice"
        };

        bool isStaff = await _ruleEngine.EvaluateRuleAsync("IsStaff", securityContext);
        
        if (!isStaff)
        {
             var userIdStr = User.FindFirst("UserId")?.Value;
             if (int.TryParse(userIdStr, out int userId))
             {
                 var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
                 var allowedAssetIds = occupancies.Select(o => o.AssetId).ToList();
                 
                if (assetId.HasValue)
                {
                    securityContext.AssetId = assetId.Value;
                    securityContext.IsPrimaryResident = allowedAssetIds.Contains(assetId.Value);
                    if (!await _ruleEngine.EvaluateRuleAsync("CanViewAsset", securityContext))
                    {
                        return Forbid();
                    }
                }
                else
                {
                    // No specific assetId, default to ALL user assets
                    if (!allowedAssetIds.Any()) return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(new PagedResult<Invoice>()));
                    // The criteria uses this assetId further down. 
                    // I will modify the criteria logic later or loop here.
                    // Actually, I'll pass multiple IDs if needed or update the service.
                }
                // Update criteria to handle null AssetId for residents
                // by using allowedAssetIds if assetId is null
                var residentAssetIds = assetId.HasValue ? new List<int> { assetId.Value } : allowedAssetIds;
             }
        }

        var criteria = new InvoiceSearchCriteria
        {
            AssociationId = associationId,
            SearchTerm = searchTerm,
            Status = status,
            StartDate = startDate,
            EndDate = endDate,
            PageNumber = pageNumber,
            PageSize = pageSize,
            SortColumn = sortColumn,
            SortDirection = sortDirection
        };

        if (assetId.HasValue)
        {
            criteria.AssetId = assetId.Value;
            var result = await _financeService.GetPagedInvoicesAsync(criteria);
            return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(result));
        }
        else
        {
            // Gather userId to find all assets for multi-asset residents
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (!isStaff && int.TryParse(userIdStr, out int userId))
            {
                var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
                var allowedAssetIds = occupancies.Select(o => o.AssetId).ToList();

                if (!allowedAssetIds.Any())
                {
                    return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(new PagedResult<Invoice>()));
                }

                criteria.AssetIds = allowedAssetIds;
                var result = await _financeService.GetPagedInvoicesAsync(criteria);
                return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(result));
            }
        }

        // Default or staff view without specified assetId
        var defaultResult = await _financeService.GetPagedInvoicesAsync(criteria);
        return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(defaultResult));
    }

    [HttpGet("summary")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetSummary([FromQuery] int? associationId = null, [FromQuery] int? assetId = null)
    {
        IEnumerable<int>? assetIds = null;
        if (!assetId.HasValue)
        {
            var roles = User.Claims.Where(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                                  .Select(c => c.Value);
            var securityContext = new SecurityContext
            {
                UserRole = string.Join(",", roles),
                UserLevel = AppRole.GetMaxLevel(User.Claims),
                AssociationId = _tenantContext.AssociationId
            };

            // Delegate ALL resident asset resolution (Occupancy + Payment History) to the FinanceService 
            // This handles both official occupants and Admins who have topped up a wallet.
            var userId = _tenantContext.UserId;
            var summaryWithUser = await _financeService.GetFinanceSummaryAsync(associationId, assetId, userId: userId);
            return Ok(ApiResponse<FinanceSummary>.SuccessResponse(summaryWithUser));
        }

        // Specific asset summary
        var summary = await _financeService.GetFinanceSummaryAsync(associationId, assetId);
        return Ok(ApiResponse<FinanceSummary>.SuccessResponse(summary));
    }


    [HttpGet("invoices/{id}")]
    public async Task<IActionResult> GetInvoice(int id, [FromQuery] int? associationId = null)
    {
        var invoice = await _financeService.GetInvoiceByIdAsync(id, associationId);
        if (invoice == null) return NotFound(ApiResponse.FailureResponse("Invoice not found."));
        return Ok(ApiResponse<Invoice>.SuccessResponse(invoice));
    }

    [HttpPost("invoices")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> CreateInvoice([FromBody] Invoice invoice)
    {
        var id = await _financeService.CreateInvoiceAsync(invoice);
        await _auditService.LogAsync("Create Invoice", "Invoice", id, assetId: invoice.AssetId);
        return CreatedAtAction(nameof(GetInvoice), new { id }, ApiResponse<int>.SuccessResponse(id, "Invoice created successfully."));
    }

    [HttpPost("invoices/{id}/settled-with-advance")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> SettleInvoiceWithAdvance(int id)
    {
        var success = await _financeService.SettleInvoiceWithAdvanceAsync(id);
        if (!success) return BadRequest(ApiResponse.FailureResponse("Unable to settle invoice with advance. Insufficient credit or invoice not found."));
        
        await _auditService.LogAsync("Manual Settlement via Advance", "Invoice", id);
        return Ok(ApiResponse.SuccessResponse("Invoice settled using advance credit."));
    }

    [HttpGet("payments")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetPayments([FromQuery] int? assetId = null)
    {
        var roles = User.Claims.Where(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                              .Select(c => c.Value);

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roles),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId,
            Action = "View",
            Resource = "Payment"
        };

        bool isStaff = await _ruleEngine.EvaluateRuleAsync("IsStaff", securityContext);
        
        if (!isStaff)
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr, out int userId))
            {
                var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
                var allowedAssetIds = occupancies.Select(o => o.AssetId).ToList();
                
                if (assetId.HasValue)
                {
                    securityContext.AssetId = assetId.Value;
                    securityContext.IsPrimaryResident = allowedAssetIds.Contains(assetId.Value);
                    if (!await _ruleEngine.EvaluateRuleAsync("CanViewAsset", securityContext))
                    {
                        return Forbid();
                    }
                }
                else
                {
                    if (!allowedAssetIds.Any()) return Ok(ApiResponse<IEnumerable<Payment>>.SuccessResponse(new List<Payment>()));
                    assetId = allowedAssetIds.First();
                }
            }
        }

        var payments = await _financeService.GetPaymentsAsync();
        if (assetId.HasValue)
        {
            payments = payments.Where(p => p.AssetId == assetId.Value);
        }
        else if (!isStaff)
        {
            // If not staff and somehow escaped assetId logic, return empty
            return Ok(ApiResponse<IEnumerable<Payment>>.SuccessResponse(new List<Payment>()));
        }

        return Ok(ApiResponse<IEnumerable<Payment>>.SuccessResponse(payments));
    }
    
    [HttpGet("advances")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetAdvances(
        [FromQuery] int? assetId = null,
        [FromQuery] string? searchTerm = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string sortColumn = "Date",
        [FromQuery] string sortDirection = "DESC")
    {
        var roles = User.Claims.Where(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                              .Select(c => c.Value);

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roles),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId,
            Action = "View",
            Resource = "Payment"
        };

        bool isStaff = await _ruleEngine.EvaluateRuleAsync("IsStaff", securityContext);
        int? userId = null;
        
        if (!isStaff)
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr, out int uid))
            {
                userId = uid;
                var occupancies = await _peopleService.GetOccupancyByUserIdAsync(uid);
                var allowedAssetIds = occupancies.Select(o => o.AssetId).ToList();
                
                if (assetId.HasValue && !allowedAssetIds.Contains(assetId.Value))
                {
                    return Forbid();
                }
            }
        }

        var criteria = new AdvanceSearchCriteria
        {
            AssociationId = _tenantContext.AssociationId,
            UserId = userId,
            AssetId = assetId,
            SearchTerm = searchTerm,
            Status = status,
            StartDate = startDate,
            EndDate = endDate,
            PageNumber = pageNumber,
            PageSize = pageSize,
            SortColumn = sortColumn,
            SortDirection = sortDirection
        };

        var result = await _financeService.GetPagedAdvancesAsync(criteria);
        return Ok(ApiResponse<PagedResult<AdvancePaymentHistory>>.SuccessResponse(result));
    }

    [HttpPost("payments")]
    public async Task<IActionResult> CreatePayment([FromBody] Payment payment)
    {
        var id = await _financeService.CreatePaymentAsync(payment);
        await _auditService.LogAsync("Record Payment", "Payment", id, assetId: payment.AssetId);
        return Ok(ApiResponse<int>.SuccessResponse(id, "Payment recorded successfully."));
    }

    [HttpGet("transactions/asset/{assetId}")]
    public async Task<IActionResult> GetAssetTransactions(int assetId)
    {
        if (!await IsAuthorizedForAsset(assetId, "View")) return Forbid();
        var transactions = await _financeService.GetAssetTransactionsAsync(assetId);
        return Ok(ApiResponse<IEnumerable<Transaction>>.SuccessResponse(transactions));
    }

    [HttpGet("balance/asset")]
    [HttpGet("balance/asset/{assetId}")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetAssetBalance([FromQuery] int? assetId = null, [FromRoute] int? rAssetId = null)
    {
        var idToUse = assetId ?? rAssetId;
        var tenantId = _tenantContext.TenantId;
        var associationId = _tenantContext.AssociationId;
        var assetIds = new List<int>();

        if (idToUse.HasValue)
        {
            if (!await IsAuthorizedForAsset(idToUse.Value, "View")) return Forbid();
            assetIds.Add(idToUse.Value);
        }
        else
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr, out int userId))
            {
                var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
                assetIds.AddRange(occupancies.Select(o => o.AssetId));
            }
        }

        if (!assetIds.Any()) return Ok(ApiResponse<decimal>.SuccessResponse(0));

        decimal totalBalance = 0;
        foreach (var aid in assetIds)
        {
            totalBalance += await _financeService.GetAssetBalanceAsync(aid);
        }

        return Ok(ApiResponse<decimal>.SuccessResponse(totalBalance));
    }

    private async Task<bool> IsAuthorizedForAsset(int assetId, string action = "View")
    {
        var roles = User.Claims.Where(c => c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role)
                             .Select(c => c.Value);

        var securityContext = new SecurityContext
        {
            UserRole = string.Join(",", roles),
            UserLevel = AppRole.GetMaxLevel(User.Claims),
            AssociationId = _tenantContext.AssociationId,
            AssetId = assetId,
            Action = action,
            Resource = "Asset"
        };

        var userIdStr = User.FindFirst("UserId")?.Value;
        if (int.TryParse(userIdStr, out int userId))
        {
            securityContext.IsPrimaryResident = await _peopleService.IsPrimaryResidentForAssetAsync(userId, assetId);
        }

        string workflowName = action == "Manage" ? "CanManageAsset" : (action == "View" && securityContext.UserLevel == AppRole.LevelResident ? "CanViewAsset" : "CanViewAsset");
        // Actually, just let the rule engine handle it, but ensured we call the right one.
        // The fix is in the rule engine or here. Let's make it simpler:
        if (action == "View" && securityContext.UserLevel >= AppRole.LevelResident)
        {
            // If they are a resident for this asset, let them view.
            var userIdStr2 = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr2, out int uid))
            {
                var occupancies = await _peopleService.GetOccupancyByUserIdAsync(uid);
                if (occupancies.Any(o => o.AssetId == assetId)) return true;
            }
        }
        
        return await _ruleEngine.EvaluateRuleAsync(workflowName, securityContext);
    }

    [HttpGet("transactions/tenant")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GetTenantTransactions([FromQuery] DateTime? start, [FromQuery] DateTime? end)
    {
        var transactions = await _financeService.GetTenantTransactionsAsync(start, end);
        return Ok(ApiResponse<IEnumerable<Transaction>>.SuccessResponse(transactions));
    }

    [HttpGet("bank-details")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetBankDetails()
    {
        var details = await _financeService.GetBankDetailsAsync(_tenantContext.AssociationId);
        return Ok(ApiResponse<AssociationBankDetails>.SuccessResponse(details ?? new AssociationBankDetails { AssociationId = _tenantContext.AssociationId }));
    }

    [HttpPost("bank-details")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> UpdateBankDetails([FromBody] AssociationBankDetails details)
    {
        try
        {
            details.AssociationId = _tenantContext.AssociationId;
            var success = await _financeService.UpdateBankDetailsAsync(details);
            return success ? Ok(ApiResponse.SuccessResponse("Bank details updated.")) : BadRequest(ApiResponse.FailureResponse("Failed to update bank details."));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse.FailureResponse($"Error saving bank details: {ex.Message}"));
        }
    }

    [HttpGet("fine-settings")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GetFineSettings([FromQuery] int associationId)
    {
        var settings = await _fineService.GetSettingsAsync(associationId);
        if (settings == null)
        {
            return Ok(ApiResponse<FineSettings>.SuccessResponse(new FineSettings { AssociationId = associationId, TenantId = _tenantContext.TenantId }));
        }
        return Ok(ApiResponse<FineSettings>.SuccessResponse(settings));
    }

    [HttpPost("fine-settings")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> SaveFineSettings([FromBody] FineSettings settings)
    {
        settings.TenantId = _tenantContext.TenantId;
        await _fineService.SaveSettingsAsync(settings);
        await _auditService.LogAsync("Update Fine Settings", "Association", settings.AssociationId);
        return Ok(ApiResponse<bool>.SuccessResponse(true));
    }
}
