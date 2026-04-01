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
            AssetId = request.AssetId,
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
            // FULFILL VIA UNIFIED PATH (Safe and Idempotent)
            await CompletePaymentAsync(request.RazorpayPaymentId, request.RazorpayOrderId, request.RazorpaySignature, _tenantContext.TenantId);
        }

        return isValid;
    }

    public async Task ProcessWebhookAsync(string payload, string signature)
    {
        int? tenantId = null;
        string eventType = "webhook_received";
        string? razorpayOrderId = null;
        string? razorpayPaymentId = null;

        try
        {
            using var doc = JsonDocument.Parse(payload);
            var root = doc.RootElement;

            // 1. Extract Event Type
            if (root.TryGetProperty("event", out var eventProperty))
                eventType = eventProperty.GetString() ?? eventType;

            // 2. Extract Data from Payload
            if (root.TryGetProperty("payload", out var payloadNode))
            {
                // payment.captured gives back payment entity
                if (payloadNode.TryGetProperty("payment", out var pNode))
                {
                    var entity = pNode.GetProperty("entity");
                    if (entity.TryGetProperty("id", out var pid)) razorpayPaymentId = pid.GetString();
                    if (entity.TryGetProperty("order_id", out var oid)) razorpayOrderId = oid.GetString();
                    
                    // Extract Tenant Id from notes stored in the payment
                    if (entity.TryGetProperty("notes", out var notes) && notes.TryGetProperty("tenant_id", out var tId))
                    {
                        if (tId.ValueKind == JsonValueKind.Number) tenantId = tId.GetInt32();
                        else if (tId.ValueKind == JsonValueKind.String && int.TryParse(tId.GetString(), out int parsed)) tenantId = parsed;
                    }
                }
                // order.paid gives back order entity
                else if (payloadNode.TryGetProperty("order", out var oNode) && oNode.TryGetProperty("entity", out var entity))
                {
                    if (entity.TryGetProperty("id", out var oid)) razorpayOrderId = oid.GetString();
                }
            }

            // 3. SECURITY: Verify signature if secret is configured (MANDATORY if configured)
            if (tenantId.HasValue)
            {
                var config = await _repository.GetPaymentConfigAsync(tenantId.Value);
                if (config != null && !string.IsNullOrEmpty(config.RazorpayWebhookSecret))
                {
                    bool isWebhookValid = _razorpayClient.VerifyWebhookSignature(payload, signature, config.RazorpayWebhookSecret);
                    if (!isWebhookValid)
                    {
                        Console.WriteLine($"SECURITY ALERT: Invalid Razorpay Webhook Signature for Tenant {tenantId}");
                        return; // REJECT
                    }
                }
            }

            // 4. BUSINESS LOGIC (Switch based on Event Type)
            switch (eventType)
            {
                case "payment.captured":
                    if (tenantId.HasValue && !string.IsNullOrEmpty(razorpayPaymentId) && !string.IsNullOrEmpty(razorpayOrderId))
                    {
                        // Process Fulfillment
                        await CompletePaymentAsync(razorpayPaymentId, razorpayOrderId, "WEBHOOK_VERIFIED", tenantId.Value);
                    }
                    break;

                case "payment.failed":
                    if (tenantId.HasValue && !string.IsNullOrEmpty(razorpayOrderId))
                    {
                        await _repository.UpdateOrderStatusAsync(razorpayOrderId, "Failed", tenantId.Value);
                        // Notify UI
                        await _hubContext.Clients.Group($"Tenant_{tenantId}").SendAsync("ReceiveNotification", $"Payment failed for Order {razorpayOrderId}");
                    }
                    break;

                default:
                    Console.WriteLine($"Webhook received but not processed: {eventType}");
                    break;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error processing Razorpay webhook: {ex.Message}");
        }

        // 5. Always log the webhook for auditing
        var log = new PaymentWebhookLog
        {
            TenantId = tenantId,
            EventType = eventType,
            RawPayload = payload,
            Signature = signature,
            IsProcessed = true // Marked processed as we handled it in the switch
        };
        await _repository.CreateWebhookLogAsync(log);
    }

    /// <summary>
    /// UNIFIED FULFILLMENT PATH
    /// Ensures payment processing is idempotent, secure, and preserves event ordering.
    /// </summary>
    private async Task CompletePaymentAsync(string paymentId, string orderId, string signature, int tenantId)
    {
        // 1. IDEMPOTENCY CHECK
        if (await _repository.TransactionExistsAsync(paymentId, tenantId))
        {
            return; // Already processed
        }

        // 2. FETCH ORDER DETAILS
        var dbOrder = await _repository.GetOrderByRazorpayIdAsync(orderId, tenantId);
        if (dbOrder == null)
        {
            Console.WriteLine($"FULFILLMENT ERROR: Order {orderId} not found in database for Tenant {tenantId}");
            return;
        }

        // 3. EVENT ORDERING PROTECTION: Prevent overwriting success if already paid
        if (dbOrder.Status == "Paid")
        {
            return; // Already marked paid
        }

        // 4. RECOVERY CONFIG (Tenant context might be missing in webhook)
        var config = await _repository.GetPaymentConfigAsync(tenantId);
        if (config == null) return;

        // 5. PREPARE TRANSACTION DATA
        var bankDetails = await _financeService.GetBankDetailsAsync(dbOrder.AssociationId);
        string? method = null, bank = null, rrn = null, cardNetwork = null;
        decimal? fee = null, tax = null;
        string rawResponse = "Processing fulfillment";

        try
        {
            // Always fetch fresh details from Razorpay during fulfillment
            var details = await _razorpayClient.GetPaymentDetailsAsync(paymentId, config.RazorpayKeyId, config.RazorpayKeySecret);
            rawResponse = details.GetRawText();
            
            method = details.TryGetProperty("method", out var m) ? m.GetString() : null;
            bank = details.TryGetProperty("bank", out var b) ? b.GetString() : null;
            fee = details.TryGetProperty("fee", out var f) && f.ValueKind == JsonValueKind.Number ? f.GetInt32() / 100m : null;
            tax = details.TryGetProperty("tax", out var t) && t.ValueKind == JsonValueKind.Number ? t.GetInt32() / 100m : null;

            // Extract Reference numbers
            if (details.TryGetProperty("acquirer_data", out var ad))
            {
                if (ad.TryGetProperty("bank_transaction_id", out var btid)) rrn = btid.GetString();
                else if (ad.TryGetProperty("rrn", out var r)) rrn = r.GetString();
                else if (ad.TryGetProperty("upi_transaction_id", out var utid)) rrn = utid.GetString();
            }

            if (details.TryGetProperty("card", out var card) && card.TryGetProperty("network", out var net))
                cardNetwork = net.GetString();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: Could not fetch detailed payment info from Razorpay for {paymentId}: {ex.Message}");
        }

        // 6. RECORD TRANSACTION
        var transaction = new PaymentTransaction
        {
            TenantId = tenantId,
            AssociationId = dbOrder.AssociationId,
            PaymentOrderId = dbOrder.Id,
            RazorpayPaymentId = paymentId,
            RazorpayOrderId = orderId,
            RazorpaySignature = signature,
            Status = "Captured",
            Amount = dbOrder.Amount,
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
        await _repository.UpdateOrderStatusAsync(orderId, "Paid", tenantId);

        // 7. FINALIZE ACCOUNTING LEDGER (Unified Financial Record)
        await _financeService.CreatePaymentAsync(new Payment
        {
            AssetId = dbOrder.AssetId,
            InvoiceId = dbOrder.InvoiceId,
            Amount = dbOrder.Amount,
            Currency = dbOrder.Currency,
            Status = "Completed",
            UserId = dbOrder.UserId,
            Notes = dbOrder.InvoiceId.HasValue ? $"Payment for Invoice #{dbOrder.InvoiceId}" : "Advance Payment",
            GatewayReference = paymentId
        });

        // 8. NOTIFY UI
        await _hubContext.Clients.Group($"Tenant_{tenantId}").SendAsync("ReceiveNotification", $"Payment completed successfully for Order {orderId}");
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
