using AssociationManager.Shared.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Models;
using AssociationManager.Shared.Enums;
using AssociationManager.Services.Billing;
using Hangfire;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Distributed;
using System;
using System.Text.Json;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using AssociationManager.Realtime.Hubs;

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
    private readonly BillingBatchService _batchService;
    private readonly IRuleEngineService _ruleEngine;
    private readonly IFineService _fineService;
    private readonly IInvoicePdfService _pdfService;
    private readonly IHubContext<NotificationHub> _hubContext;

    public FinanceController(
        IFinanceService financeService, 
        IAuditService auditService,
        ITenantContext tenantContext,
        IPeopleService peopleService,
        BillingBatchService batchService,
        IRuleEngineService ruleEngine,
        IFineService fineService, 
        IInvoicePdfService pdfService,
        IHubContext<NotificationHub> hubContext)
    {
        _financeService = financeService;
        _auditService = auditService;
        _tenantContext = tenantContext;
        _peopleService = peopleService;
        _batchService = batchService;
        _ruleEngine = ruleEngine;
        _fineService = fineService;
        _pdfService = pdfService;
        _hubContext = hubContext;
    }

    [HttpPost("batch-generate")]
    [Authorize(Policy = "RequireFinanceManager")]
    public IActionResult GenerateBatch([FromBody] InvoiceBatchRequest request)
    {
        var trackingId = Guid.NewGuid().ToString("N");
        BackgroundJob.Enqueue<BillingBatchService>(x => x.ExecuteBatchJobAsync(request, _tenantContext.TenantId, trackingId));
        return Accepted(ApiResponse<string>.SuccessResponse(trackingId, "Billing batch generation has been queued. Tracking ID: " + trackingId));
    }

    [HttpPost("batches/preview")]
    [Authorize(Policy = "RequireFinanceManager")]
    public IActionResult PreviewBatch([FromBody] InvoiceBatchRequest request)
    {
        request.DryRun = true;
        
        // Generate a tracking ID for the job
        var trackingId = Guid.NewGuid().ToString("N");
        
        // Enqueue the background job and pass the trackingId
        BackgroundJob.Enqueue<BillingBatchService>(x => x.ExecuteBatchJobAsync(request, _tenantContext.TenantId, trackingId));
        
        return Accepted(ApiResponse<string>.SuccessResponse(trackingId, "Batch preview generation has started. Tracking ID: " + trackingId));
    }

    [HttpGet("batches/preview/{trackingId}")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GetPreviewResult(string trackingId)
    {
        var tempPath = Path.Combine(Path.GetTempPath(), $"batch_preview_{trackingId}.json");
        Console.WriteLine($"[Diagnostic] Looking for preview file: {tempPath}, Exists: {System.IO.File.Exists(tempPath)}");
        if (System.IO.File.Exists(tempPath))
        {
            var json = await System.IO.File.ReadAllTextAsync(tempPath);
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var result = JsonSerializer.Deserialize<InvoiceBatchResult>(json, options);
            if (result == null) return NotFound(ApiResponse.FailureResponse("Could not parse preview data."));
            Console.WriteLine($"[Diagnostic] Preview loaded: {result?.Previews?.Count ?? 0} items, Total: {result?.TotalAmount}");
            return Ok(ApiResponse<InvoiceBatchResult>.SuccessResponse(result!));
        }
        
        return NotFound(ApiResponse.FailureResponse("Preview not ready or expired."));
    }

    [HttpPost("batches/draft")]
    [Authorize(Policy = "RequireFinanceManager")]
    public IActionResult CreateDraftBatch([FromBody] InvoiceBatchRequest request)
    {
        request.DryRun = false;
        var trackingId = Guid.NewGuid().ToString("N");
        BackgroundJob.Enqueue<BillingBatchService>(x => x.ExecuteBatchJobAsync(request, _tenantContext.TenantId, trackingId));
        return Accepted(ApiResponse<string>.SuccessResponse(trackingId, "Draft billing batch creation has been queued. Tracking ID: " + trackingId));
    }

    [HttpGet("batches")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> GetBatches([FromQuery] int associationId)
    {
        var result = await _batchService.GetBatchesAsync(associationId, _tenantContext.TenantId);
        return Ok(ApiResponse<IEnumerable<BillingBatch>>.SuccessResponse(result));
    }

    [HttpPost("batches/{id}/finalize")]
    [Authorize(Policy = "RequireFinanceManager")]
    public IActionResult CommitBatch(int id)
    {
        Hangfire.BackgroundJob.Enqueue<IFinanceService>(x => x.CommitBatchAsync(id, _tenantContext.TenantId, _tenantContext.AssociationId));
        return Ok(ApiResponse<bool>.SuccessResponse(true, "Batch commitment has been queued. Invoices will transition to Unpaid shortly."));
    }

    [HttpPost("batches/notify-completion")]
    [AllowAnonymous] // Allow background worker to call this without JWT
    public async Task<IActionResult> NotifyBatchCompletion(
        [FromQuery] int tenantId, 
        [FromQuery] int associationId, 
        [FromQuery] string period, 
        [FromQuery] string? jobId = null, 
        [FromQuery] string? status = "BATCH_READY")
    {
        // Notification payload: STATUS|AssociationId|Period|JobId
        var payload = $"{status}|{associationId}|{period}|{jobId}";
        await _hubContext.Clients.Group($"Tenant_{tenantId}").SendAsync("ReceiveNotification", payload);
        return Ok();
    }

    [HttpDelete("batches/{id}")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> DeleteBatch(int id)
    {
        try
        {
            var success = await _financeService.DeleteBatchAsync(id);
            if (!success) return BadRequest(ApiResponse.FailureResponse("Failed to delete batch. It may not exist or is not in Draft state."));
            
            await _auditService.LogAsync("Delete Billing Batch", "BillingBatch", id);
            return Ok(ApiResponse.SuccessResponse("Billing batch and its draft invoices deleted successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse.FailureResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse.FailureResponse($"Error deleting batch: {ex.Message}"));
        }
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
        [FromQuery] string sortDirection = "DESC",
        [FromQuery] bool includeDrafts = false)
    {
        var userLevel = AppRole.GetMaxLevel(User.Claims);
        bool isStaff = userLevel >= AppRole.LevelFinanceManager;
        
        if (!isStaff)
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr, out int userId))
            {
                var allowedAssetIds = await GetUserAssetIdsAsync(userId);
                if (assetId.HasValue)
                {
                    if (!allowedAssetIds.Contains(assetId.Value)) return Forbid();
                }
                else
                {
                    if (!allowedAssetIds.Any()) return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(new PagedResult<Invoice>()));
                    // Criteria will pick this up via .AssetIds further down
                }
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
            SortDirection = sortDirection,
            IncludeDrafts = includeDrafts
        };

        if (assetId.HasValue)
        {
            criteria.AssetId = assetId.Value;
            var result = await _financeService.GetPagedInvoicesAsync(criteria);
            return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(result));
        }
        else
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (!isStaff && int.TryParse(userIdStr, out int userId))
            {
                var allowedAssetIds = await GetUserAssetIdsAsync(userId);
                if (!allowedAssetIds.Any()) return Ok(ApiResponse<PagedResult<Invoice>>.SuccessResponse(new PagedResult<Invoice>()));

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
        if (!assetId.HasValue)
        {
            var userId = _tenantContext.UserId;
            var summaryWithUser = await _financeService.GetFinanceSummaryAsync(associationId, assetId, userId: userId);
            return Ok(ApiResponse<FinanceSummary>.SuccessResponse(summaryWithUser));
        }

        var summary = await _financeService.GetFinanceSummaryAsync(associationId, assetId);
        return Ok(ApiResponse<FinanceSummary>.SuccessResponse(summary));
    }

    [HttpGet("overview")]
    [Authorize(Policy = "RequireResident")]
    public async Task<IActionResult> GetBillingOverview([FromQuery] int? associationId = null, [FromQuery] int? assetId = null)
    {
        var aid = associationId ?? _tenantContext.AssociationId;
        var userId = _tenantContext.UserId;

        // Resolve AssetIds for Residents to enforce data isolation
        List<int>? residentAssetIds = null;
        var userLevel = AppRole.GetMaxLevel(User.Claims);
        if (userLevel < AppRole.LevelFinanceManager)
        {
            var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
            residentAssetIds = occupancies.Select(o => o.AssetId).ToList();
            
            // If they have no assets, they shouldn't see anything
            if (!residentAssetIds.Any())
            {
                return Ok(ApiResponse<BillingOverview>.SuccessResponse(new BillingOverview 
                { 
                    RecentPayments = new List<Payment>(),
                    Invoices = new PagedResult<Invoice>()
                }));
            }
        }

        // Parallel fetch all billing components
        // Optimized: Only fetch the Top 20 recent payments for the overview dashboard
        var paymentsTask = _financeService.GetRecentPaymentsAsync(aid, 20, residentAssetIds);
        var balanceTask = _financeService.GetFinanceSummaryAsync(aid, assetId, assetIds: residentAssetIds, userId: userId);
        var batchesTask = _batchService.GetBatchesAsync(aid, _tenantContext.TenantId);
        
        // Initial page of invoices
        var criteria = new InvoiceSearchCriteria
        {
            AssociationId = aid,
            AssetId = assetId,
            AssetIds = residentAssetIds,
            PageNumber = 1,
            PageSize = 10,
            SortColumn = "CreatedDate",
            SortDirection = "DESC"
        };
        var invoicesTask = _financeService.GetPagedInvoicesAsync(criteria);

        await Task.WhenAll(paymentsTask, balanceTask, batchesTask, invoicesTask);

        var overview = new BillingOverview
        {
            RecentPayments = (await paymentsTask).Where(p => !assetId.HasValue || p.AssetId == assetId.Value).ToList(),
            AdvanceBalance = (await balanceTask).TotalAdvanceCredits,
            ExistingBatches = (await batchesTask).ToList(),
            Invoices = await invoicesTask
        };

        return Ok(ApiResponse<BillingOverview>.SuccessResponse(overview));
    }


    [HttpGet("invoices/{id}")]
    public async Task<IActionResult> GetInvoice(int id, [FromQuery] int? associationId = null)
    {
        var result = await _financeService.GetInvoiceByIdAsync(id, associationId);
        if (result == null) return NotFound(ApiResponse<Invoice>.ErrorResponse("Invoice not found."));
        return Ok(ApiResponse<Invoice>.SuccessResponse(result));
    }

    [HttpGet("invoices/{id}/pdf")]
    public async Task<IActionResult> DownloadInvoicePdf(int id)
    {
        try
        {
            var pdfBytes = await _pdfService.GenerateInvoicePdfAsync(id);
            var fileName = $"Invoice_{id}_{DateTime.UtcNow:yyyyMMdd}.pdf";
            return File(pdfBytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse<string>.ErrorResponse($"Failed to generate PDF: {ex.Message}"));
        }
    }

    [HttpPost("invoices")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> CreateInvoice([FromBody] Invoice invoice)
    {
        var id = await _financeService.CreateInvoiceAsync(invoice);
        await _auditService.LogAsync("Create Invoice", "Invoice", id, assetId: invoice.AssetId);
        return CreatedAtAction(nameof(GetInvoice), new { id }, ApiResponse<int>.SuccessResponse(id, "Invoice created successfully."));
    }

    [HttpPost("invoices/adjust")]
    [Authorize(Policy = "RequireFinanceManager")]
    public async Task<IActionResult> AdjustDraftInvoice([FromBody] AdjustInvoiceRequest request)
    {
        var success = await _financeService.AdjustInvoiceLineItemsAsync(request.InvoiceId, request.LineItems);
        if (!success) return BadRequest(ApiResponse.FailureResponse("Failed to adjust invoice. It may not exist or is not in Draft status."));
        return Ok(ApiResponse.SuccessResponse("Invoice adjusted successfully."));
    }

    [HttpGet("invoices/{id}/history")]
    public async Task<IActionResult> GetInvoiceHistory(int id)
    {
        var history = await _financeService.GetInvoicePaymentHistoryAsync(id);
        return Ok(ApiResponse<IEnumerable<PaymentHistoryItem>>.SuccessResponse(history));
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

        var userLevel = AppRole.GetMaxLevel(User.Claims);
        bool isStaff = userLevel >= AppRole.LevelFinanceManager;
        
        if (!isStaff)
        {
            var userIdStr = User.FindFirst("UserId")?.Value;
            if (int.TryParse(userIdStr, out int userId))
            {
                var allowedAssetIds = await GetUserAssetIdsAsync(userId);
                
                if (assetId.HasValue)
                {
                    if (!allowedAssetIds.Contains(assetId.Value))
                    {
                        return Forbid();
                    }
                }
                else
                {
                    if (!allowedAssetIds.Any()) return Ok(ApiResponse<IEnumerable<Payment>>.SuccessResponse(new List<Payment>()));
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
                var allowedAssetIds = await GetUserAssetIdsAsync(uid);
                
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

    [HttpPost("maintenance/post-overdue-fines")]
    [Authorize(Policy = "RequireAssociationAdmin")]
    public async Task<IActionResult> PostOverdueFines()
    {
        var count = await _financeService.PostOverdueFinesAsync();
        return Ok(ApiResponse<int>.SuccessResponse(count, $"Batch processed fine posting. {count} new fine items recorded in the ledger."));
    }

    private async Task<List<int>> GetUserAssetIdsAsync(int userId)
    {
        var occupancies = await _peopleService.GetOccupancyByUserIdAsync(userId);
        return occupancies.Select(o => o.AssetId).ToList();
    }
}
