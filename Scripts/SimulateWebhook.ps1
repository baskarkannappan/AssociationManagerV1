# Simulate a Razorpay Webhook Callback to localhost
$webhookUrl = "https://localhost:7000/api/payments/webhook"
$tenantId = 1 # Replace with your actual TenantId if different

$payload = @{
    event = "payment.captured"
    payload = @{
        payment = @{
            entity = @{
                id = "pay_simulated_$(Get-Date -Format 'yyyyMMddHHmmss')"
                amount = 50000
                currency = "INR"
                status = "captured"
                notes = @{
                    tenant_id = $tenantId
                    association_id = 1013
                }
            }
        }
    }
} | ConvertTo-Json -Depth 10

$headers = @{
    "Content-Type" = "application/json"
    "X-Razorpay-Signature" = "simulated_signature_for_testing"
}

Write-Host "Sending simulated webhook to $webhookUrl..." -ForegroundColor Cyan
try {
    # Ignore SSL certificate errors for localhost
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -Headers $headers
    Write-Host "Success! Webhook sent. Check your [assoc].[PaymentWebhookLogs] table." -ForegroundColor Green
} catch {
    Write-Host "Error sending webhook: $_" -ForegroundColor Red
    Write-Host "Make sure your API project is running on https://localhost:7000" -ForegroundColor Yellow
}
