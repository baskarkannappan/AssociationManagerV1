using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.SignalR;
using AssociationManager.Realtime.Hubs;
using System;
using System.Text.Json;
using System.Threading.Tasks;

namespace AssociationManager.Services.Implementations;

public class PaymentServiceV2 : IPaymentServiceV2
{
    private readonly IRazorpayRepository _repository;
    private readonly AssociationManager.Services.Razorpay.RazorpayClient _razorpayClient;
    private readonly ITenantContext _tenantContext;
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly IFinanceService _financeService;

    public PaymentServiceV2(
        IRazorpayRepository repository,
        AssociationManager.Services.Razorpay.RazorpayClient razorpayClient,
        ITenantContext tenantContext,
        IHubContext<NotificationHub> hubContext,
        IFinanceService financeService)
    {
        _repository = repository;
        _razorpayClient = razorpayClient;
        _tenantContext = tenantContext;
        _hubContext = hubContext;
        _financeService = financeService;
    }

    public async Task<RazorpayOrderResponse> CreateOrderAsync(RazorpayOrderRequest request)
    {
        var config = await _repository.GetPaymentConfigAsync(_tenantContext.TenantId);
        if (config == null) throw new Exception("Payment configuration not found for this tenant.");

        var receipt = request.Receipt ?? $"INV_{request.InvoiceId ?? 0}_{DateTime.Now.Ticks}";
        
        // Include Tenant and Association IDs in the notes so they return in the webhook payload
        var notes = new { 
            tenant_id = _tenantContext.TenantId, 
            association_id = _tenantContext.AssociationId,
            invoice_id = request.InvoiceId ?? 0,
            description = request.Description ?? "Association Payment"
        };

        var razorpayOrderId = await _razorpayClient.CreateOrderAsync(request.Amount, request.Currency, receipt, config.RazorpayKeyId, config.RazorpayKeySecret, notes);

        // Snapshot Association Bank Details
        var bankDetails = await _financeService.GetBankDetailsAsync(_tenantContext.AssociationId);

        var order = new PaymentOrder
        {
            TenantId = _tenantContext.TenantId,
            AssociationId = _tenantContext.AssociationId,
            UserId = _tenantContext.UserId,
            RazorpayOrderId = razorpayOrderId,
            Amount = request.Amount,
            Currency = request.Currency,
            InvoiceId = request.InvoiceId,
            Receipt = receipt,
            Status = "Created",
            PrimaryAccountName = bankDetails?.PrimaryAccountName,
            PrimaryAccountNumber = bankDetails?.PrimaryAccountNumber
        };

        await _repository.CreateOrderAsync(order);

        return new RazorpayOrderResponse
        {
            OrderId = razorpayOrderId,
            KeyId = config.RazorpayKeyId,
            Amount = request.Amount,
            Currency = request.Currency,
            Status = "Created"
        };
    }

    public async Task<bool> VerifySignatureAsync(RazorpayVerifyRequest request)
    {
        var config = await _repository.GetPaymentConfigAsync(_tenantContext.TenantId);
        if (config == null) return false;

        bool isValid = _razorpayClient.VerifySignature(request.RazorpayOrderId, request.RazorpayPaymentId, request.RazorpaySignature, config.RazorpayKeySecret);
        
        if (isValid)
        {
            // IDEMPOTENCY CHECK: Ensure we don't duplicate logs
            if (await _repository.TransactionExistsAsync(request.RazorpayPaymentId, _tenantContext.TenantId))
            {
                return true; // Already processed
            }

            var dbOrder = await _repository.GetOrderByRazorpayIdAsync(request.RazorpayOrderId, _tenantContext.TenantId);
            
            // Snapshot Association Bank Details
            var bankDetails = await _financeService.GetBankDetailsAsync(_tenantContext.AssociationId);

            // Fetch detailed info from Razorpay to capture fees, tax, and RRN
            string? method = null, bank = null, rrn = null, cardNetwork = null;
            decimal? fee = null, tax = null;
            string rawResponse = "Verified via frontend";

            try
            {
                var details = await _razorpayClient.GetPaymentDetailsAsync(request.RazorpayPaymentId, config.RazorpayKeyId, config.RazorpayKeySecret);
                rawResponse = details.GetRawText();
                
                method = details.TryGetProperty("method", out var m) ? m.GetString() : null;
                bank = details.TryGetProperty("bank", out var b) ? b.GetString() : null;
                fee = details.TryGetProperty("fee", out var f) && f.ValueKind == System.Text.Json.JsonValueKind.Number ? f.GetInt32() / 100m : null;
                tax = details.TryGetProperty("tax", out var t) && t.ValueKind == System.Text.Json.JsonValueKind.Number ? t.GetInt32() / 100m : null;

                // Extract RRN or Network reference
                if (details.TryGetProperty("acquirer_data", out var ad))
                {
                    if (ad.TryGetProperty("bank_transaction_id", out var btid)) rrn = btid.GetString();
                    else if (ad.TryGetProperty("rrn", out var r)) rrn = r.GetString();
                    else if (ad.TryGetProperty("upi_transaction_id", out var utid)) rrn = utid.GetString();
                }

                if (details.TryGetProperty("card", out var card) && card.TryGetProperty("network", out var net))
                {
                    cardNetwork = net.GetString();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error fetching detailed payment info: {ex.Message}");
            }

            var transaction = new PaymentTransaction
            {
                TenantId = _tenantContext.TenantId,
                AssociationId = _tenantContext.AssociationId,
                PaymentOrderId = dbOrder?.Id,
                RazorpayPaymentId = request.RazorpayPaymentId,
                RazorpayOrderId = request.RazorpayOrderId,
                RazorpaySignature = request.RazorpaySignature,
                Status = "Captured",
                Amount = dbOrder?.Amount ?? 0,
                RawResponse = rawResponse,
                PrimaryAccountName = bankDetails?.PrimaryAccountName,
                PrimaryAccountNumber = bankDetails?.PrimaryAccountNumber,
                PaymentMethod = method,
                BankName = bank,
                BankRrn = rrn,
                CardNetwork = cardNetwork,
                GatewayFee = fee,
                GatewayTax = tax
            };

            await _repository.CreateTransactionAsync(transaction);
            await _repository.UpdateOrderStatusAsync(request.RazorpayOrderId, "Paid", _tenantContext.TenantId);

            // Update Invoice Status if linked
            if (dbOrder?.InvoiceId.HasValue == true)
            {
                await _financeService.UpdateInvoiceStatusAsync(dbOrder.InvoiceId.Value, "Paid", dbOrder.AssociationId);
            }

            // Notify UI
            await _hubContext.Clients.Group($"Tenant_{_tenantContext.TenantId}").SendAsync("ReceiveNotification", $"Payment successful for Order {request.RazorpayOrderId}");
        }

        return isValid;
    }

    public async Task ProcessWebhookAsync(string payload, string signature)
    {
        int? tenantId = null;
        string eventType = "webhook_received";
        string? razorpayOrderId = null;

        try
        {
            using var doc = System.Text.Json.JsonDocument.Parse(payload);
            var root = doc.RootElement;

            // Extract Event Type
            if (root.TryGetProperty("event", out var eventProperty))
            {
                eventType = eventProperty.GetString() ?? eventType;
            }

            // Extract OrderId and Metadata
            if (root.TryGetProperty("payload", out var payloadNode))
            {
                var targetNode = payloadNode.TryGetProperty("payment", out var p) ? p : 
                                 payloadNode.TryGetProperty("order", out var o) ? o : default;

                if (targetNode.ValueKind != System.Text.Json.JsonValueKind.Undefined &&
                    targetNode.TryGetProperty("entity", out var entity))
                {
                    // Get Order Id
                    if (entity.TryGetProperty("order_id", out var oid)) razorpayOrderId = oid.GetString();
                    else if (entity.TryGetProperty("id", out var eid) && eventType.StartsWith("order.")) razorpayOrderId = eid.GetString();

                    // Get Tenant Id from notes
                    if (entity.TryGetProperty("notes", out var notes) &&
                        notes.TryGetProperty("tenant_id", out var tId))
                    {
                        if (tId.ValueKind == System.Text.Json.JsonValueKind.Number) tenantId = tId.GetInt32();
                        else if (tId.ValueKind == System.Text.Json.JsonValueKind.String && int.TryParse(tId.GetString(), out int parsed)) tenantId = parsed;
                    }
                }
            }

            // FALLBACK IDENTIFICATION: If notes are missing, use OrderId lookup
            if (!tenantId.HasValue && !string.IsNullOrEmpty(razorpayOrderId))
            {
                // Note: We need a cross-tenant order lookup. Assuming our database design is robust.
                // For now, we attempt to find the order by checking all available tenants (simplified approach for POC)
                // In production, you'd want a lookup table optimized for OrderId -> TenantId
                // ... logic to find tenantId from order ...
            }

            // WEBHOOK SECURITY: Verify signature if secret is configured
            if (tenantId.HasValue)
            {
                var config = await _repository.GetPaymentConfigAsync(tenantId.Value);
                if (config != null && !string.IsNullOrEmpty(config.RazorpayWebhookSecret))
                {
                    bool isWebhookValid = _razorpayClient.VerifyWebhookSignature(payload, signature, config.RazorpayWebhookSecret);
                    if (!isWebhookValid)
                    {
                        Console.WriteLine($"SECURITY ALERT: Invalid Razorpay Webhook Signature for Tenant {tenantId}");
                        return; // Drop invalid webhooks
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error parsing Razorpay webhook payload: {ex.Message}");
        }

        var log = new PaymentWebhookLog
        {
            TenantId = tenantId,
            EventType = eventType,
            RawPayload = payload,
            Signature = signature,
            IsProcessed = false
        };
        await _repository.CreateWebhookLogAsync(log);
    }

    public async Task<object> GetPaymentHistoryAsync(int invoiceId)
    {
        var transactions = await _repository.GetTransactionsByInvoiceIdAsync(invoiceId, _tenantContext.TenantId);
        var orders = await _repository.GetOrdersByInvoiceIdAsync(invoiceId, _tenantContext.TenantId);
        
        return new 
        { 
            Transactions = transactions, 
            Orders = orders 
        };
    }
}
