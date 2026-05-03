using AssociationManager.Data.Interfaces;
using AssociationManager.Services.Interfaces;
using AssociationManager.Shared.Interfaces;
using AssociationManager.Shared.Models;
using Microsoft.AspNetCore.SignalR;
using AssociationManager.Realtime.Hubs;
using System;
using System.Linq;
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
    private readonly IEmailService _emailService;
    private readonly IPeopleService _peopleService;
    private readonly IUserRepository _userRepository;
    private readonly IAssetService _assetService;

    public PaymentServiceV2(
        IRazorpayRepository repository,
        AssociationManager.Services.Razorpay.RazorpayClient razorpayClient,
        ITenantContext tenantContext,
        IHubContext<NotificationHub> hubContext,
        IFinanceService financeService,
        IEmailService emailService,
        IPeopleService peopleService,
        IUserRepository userRepository,
        IAssetService assetService)
    {
        _repository = repository;
        _razorpayClient = razorpayClient;
        _tenantContext = tenantContext;
        _hubContext = hubContext;
        _financeService = financeService;
        _emailService = emailService;
        _peopleService = peopleService;
        _userRepository = userRepository;
        _assetService = assetService;
    }

    public async Task<RazorpayOrderResponse> CreateOrderAsync(RazorpayOrderRequest request)
    {
        var config = await GetActiveConfigAsync(_tenantContext.TenantId);
        if (config == null) throw new Exception("Payment configuration not found (Master fallback also failed).");

        var receipt = request.Receipt ?? $"INV_{request.InvoiceId ?? 0}_{DateTime.Now.Ticks}";
        
        // Include Tenant and Association IDs in the notes so they return in the webhook payload
        var notes = new { 
            tenant_id = _tenantContext.TenantId, 
            association_id = _tenantContext.AssociationId,
            invoice_id = request.InvoiceId ?? 0,
            description = request.Description ?? "Association Payment"
        };

        if (string.IsNullOrEmpty(config.RazorpayKeyId) || string.IsNullOrEmpty(config.RazorpayKeySecret))
            throw new Exception("Razorpay Key ID or Secret is not configured.");

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
        var config = await GetActiveConfigAsync(_tenantContext.TenantId);
        if (config == null) return false;

        if (string.IsNullOrEmpty(config.RazorpayKeySecret)) return false;

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
                var config = await GetActiveConfigAsync(tenantId.Value);
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
        var config = await GetActiveConfigAsync(tenantId);
        if (config == null) return;

        // 5. PREPARE TRANSACTION DATA
        var bankDetails = await _financeService.GetBankDetailsAsync(dbOrder.AssociationId);
        string? method = null, bank = null, rrn = null, cardNetwork = null;
        decimal? fee = null, tax = null;
        string rawResponse = "Processing fulfillment";

        try
        {
            if (string.IsNullOrEmpty(config.RazorpayKeyId) || string.IsNullOrEmpty(config.RazorpayKeySecret))
            {
                Console.WriteLine($"FULFILLMENT ERROR: Razorpay keys missing for Tenant {tenantId}");
                return;
            }

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

        // 9. EMAIL NOTIFICATION TO ADMINS
        _ = Task.Run(() => SendPaymentNotificationToAdminsAsync(dbOrder, paymentId));
    }

    private async Task SendPaymentNotificationToAdminsAsync(PaymentOrder order, string paymentId)
    {
        try
        {
            // 1. Get Payer Details
            var payerOccupancies = await _peopleService.GetOccupancyByUserIdAsync(order.UserId);
            var payerOccupancy = payerOccupancies.FirstOrDefault(o => o.AssetId == order.AssetId) 
                                 ?? payerOccupancies.FirstOrDefault();
            
            string payerName = payerOccupancy?.PersonName ?? "Unknown Resident";
            string payerEmail = payerOccupancy?.Email ?? "Unknown Email";
            
            // 2. Get Asset Details
            string assetDetail = "N/A";
            if (order.AssetId.HasValue)
            {
                var asset = await _assetService.GetByIdAsync(order.AssetId.Value);
                assetDetail = asset?.Name ?? $"Asset ID: {order.AssetId}";
            }

            // 3. Get Association Admins
            var allUsers = await _userRepository.GetByAssociationIdAsync(order.AssociationId);
            var admins = allUsers.Where(u => u.Role == "AssociationAdmin").ToList();

            if (!admins.Any()) return;

            // 4. Construct Email
            string subject = order.InvoiceId.HasValue 
                ? $"[Payment Received] Invoice #{order.InvoiceId} - {assetDetail}"
                : $"[Wallet Top-up] {assetDetail}";

            string paymentType = order.InvoiceId.HasValue ? "Invoice Payment" : "Wallet Top-up / Advance";
            
            string htmlBody = $@"
                <div style='font-family: sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #eee; padding: 20px;'>
                    <h3 style='color: #2c3e50;'>Payment Notification</h3>
                    <p>A new payment has been processed for your association.</p>
                    <table style='width: 100%; border-collapse: collapse;'>
                        <tr><td style='padding: 8px; border: 1px solid #ddd; background: #f9f9f9;'><b>Payer Name</b></td><td style='padding: 8px; border: 1px solid #ddd;'>{payerName}</td></tr>
                        <tr><td style='padding: 8px; border: 1px solid #ddd; background: #f9f9f9;'><b>Email</b></td><td style='padding: 8px; border: 1px solid #ddd;'>{payerEmail}</td></tr>
                        <tr><td style='padding: 8px; border: 1px solid #ddd; background: #f9f9f9;'><b>Unit / Asset</b></td><td style='padding: 8px; border: 1px solid #ddd;'>{assetDetail}</td></tr>
                        <tr><td style='padding: 8px; border: 1px solid #ddd; background: #f9f9f9;'><b>Amount</b></td><td style='padding: 8px; border: 1px solid #ddd;'>{order.Currency} {order.Amount:N2}</td></tr>
                        <tr><td style='padding: 8px; border: 1px solid #ddd; background: #f9f9f9;'><b>Payment Type</b></td><td style='padding: 8px; border: 1px solid #ddd;'>{paymentType}</td></tr>
                        <tr><td style='padding: 8px; border: 1px solid #ddd; background: #f9f9f9;'><b>Transaction ID</b></td><td style='padding: 8px; border: 1px solid #ddd;'>{paymentId}</td></tr>
                        <tr><td style='padding: 8px; border: 1px solid #ddd; background: #f9f9f9;'><b>Date</b></td><td style='padding: 8px; border: 1px solid #ddd;'>{DateTime.Now:f}</td></tr>
                    </table>
                    <p style='margin-top: 20px; color: #7f8c8d; font-size: 12px;'>This is an automated notification from Association Manager. Please check your dashboard for more details.</p>
                </div>";

            foreach (var admin in admins)
            {
                await _emailService.SendEmailAsync(admin.Email, admin.Name, subject, htmlBody);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending payment notification email: {ex.Message}");
        }
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

    private async Task<TenantPaymentConfig?> GetActiveConfigAsync(int tenantId)
    {
        // 1. Try Specific Tenant Config
        var config = await _repository.GetPaymentConfigAsync(tenantId);
        
        // 2. Fallback to Master (Tenant 1) if not found or inactive
        if (config == null || !config.IsActive)
        {
            config = await _repository.GetPaymentConfigAsync(1); // Master Tenant Fallback
        }

        return config;
    }
}
